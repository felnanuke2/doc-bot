//
//  main.swift
//  EmbeddingExample
//
//  Created by LUIZ FELIPE ALVES LIMA on 22/07/25.
//
//  This is a complete, self-contained example demonstrating how to generate
//  text embeddings using a GGUF model with llama.cpp in Swift.
//
//  To run this:
//  1. Make sure you have the `llama` library available in your project.
//  2. Download the model file from: https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF
//  3. Update the `modelPath` variable in the `main` function below to point to the downloaded .gguf file.
//  4. Run the Swift script.
//

import Foundation
import llama


// MARK: - Llama Embedding Context

/// A Swift actor to safely manage llama.cpp model and context for generating embeddings.
/// This class is specifically tailored for models like nomic-embed-text, which require
/// mean pooling over token embeddings.
actor LlamaEmbeddingContext {
    private var model: OpaquePointer
    private var context: OpaquePointer
    private var batch: llama_batch
    
    // Define max batch size for sequences
    private static let maxBatchSize = 512

    /// Initializes the Llama context for embedding generation.
    private init(model: OpaquePointer, context: OpaquePointer) {
        self.model = model
        self.context = context
        // Initialize batch for multiple sequences. The batch can handle up to maxBatchSize sequences
        // and up to 4096 tokens total across all sequences.
        self.batch = llama_batch_init(4096, 0, Int32(LlamaEmbeddingContext.maxBatchSize))
    }

    deinit {
        llama_batch_free(batch)
        llama_free(context)
        llama_free_model(model)
        // llama_backend_free()
        print("Llama context cleaned up.")
    }

    /// Creates and configures a new Llama context from a model file.
    static func createContext(path: String) throws -> LlamaEmbeddingContext {
        // Ensure file exists before proceeding
        guard FileManager.default.fileExists(atPath: path) else {
            print("Error: Model file not found at \(path)")
            throw LlamaError.invalidModel
        }
        
        llama_backend_init()
        var model_params = llama_model_default_params()
        
        // Detect if running in iOS Simulator and adjust GPU acceleration accordingly
        #if targetEnvironment(simulator)
        // iOS Simulator has limited Metal support, use CPU-only processing
        model_params.n_gpu_layers = 0
        print("Running in iOS Simulator - using CPU-only processing for stability.")
        #else
        // On real devices, enable GPU acceleration for better performance
        model_params.n_gpu_layers = 99  // Offload all layers to GPU
        print("Enabling GPU acceleration with all layers offloaded to Metal.")
        #endif

        guard let model = llama_load_model_from_file(path, model_params) else {
            print("Error: Could not load model from \(path)")
            throw LlamaError.couldNotInitializeContext
        }

        let n_threads = max(1, min(8, ProcessInfo.processInfo.processorCount - 2))
        print("Using \(n_threads) threads for processing.")

        var ctx_params = llama_context_default_params()
        ctx_params.n_ctx = 2048 // The nomic model supports up to 8192
        ctx_params.n_batch = 512 // Increase batch size for better parallel processing
        ctx_params.n_threads = Int32(n_threads)
        ctx_params.n_threads_batch = Int32(n_threads)
        ctx_params.n_ubatch = 512 // Match with n_batch
        
        // CRITICAL FIX: Set both embedding flags
        ctx_params.embeddings = true
        ctx_params.pooling_type = LLAMA_POOLING_TYPE_MEAN  // Use mean pooling
        
        print("DEBUG: Context configured for embeddings with mean pooling")

        guard let context = llama_new_context_with_model(model, ctx_params) else {
            print("Error: Could not initialize context from model.")
            llama_free_model(model)
            throw LlamaError.couldNotInitializeContext
        }

        return LlamaEmbeddingContext(model: model, context: context)
    }

    func generateEmbedding(for text: String) throws -> [Float] {
        // Input validation
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("Error: Empty or whitespace-only text provided")
            throw LlamaError.embeddingGenerationFailed
        }
        
        // 1. Prepend the required prefix for nomic-embed-text.
        let prefixedText = "search_query: " + text
        print("DEBUG: Prefixed text: '\(prefixedText)'")
        
        // 2. Tokenize the text with improved error handling
        let tokens: [llama_token]
        do {
            tokens = try tokenize(text: prefixedText, add_bos: true)  // Changed to true for embedding models
        } catch {
            print("Error: Tokenization failed - \(error)")
            throw LlamaError.tokenizationFailed
        }
        
        guard !tokens.isEmpty else {
            print("Error: Tokenization produced empty token array")
            throw LlamaError.tokenizationFailed
        }
        
        print("DEBUG: Token count: \(tokens.count)")
        print("DEBUG: First few tokens: \(Array(tokens.prefix(5)))")
        
        // 3. Clear and prepare the batch
        llama_batch_clear(&batch)
        
        // Check if token count exceeds batch capacity
        guard tokens.count <= 4096 else {
            print("Error: Token count (\(tokens.count)) exceeds batch capacity (4096)")
            throw LlamaError.embeddingGenerationFailed
        }
        
        // Add all tokens to the batch for sequence processing
        for (i, token) in tokens.enumerated() {
            llama_batch_add(&batch, token, Int32(i), [0], true)  // embd=true for embeddings
        }
        batch.n_tokens = Int32(tokens.count)
        
        print("DEBUG: Batch prepared with \(batch.n_tokens) tokens")
        
        // 4. CRITICAL FIX: Use llama_encode instead of llama_decode
        let encode_result = llama_encode(context, batch)
        if encode_result != 0 {
            print("Error: llama_encode failed with code: \(encode_result)")
            throw LlamaError.embeddingGenerationFailed
        }
        
        print("DEBUG: llama_encode succeeded")
        
        // 5. APPROACH 1: Try getting sequence-level embeddings directly
        let n_embd = Int(llama_n_embd(model))
        print("DEBUG: Embedding dimension: \(n_embd)")
        
        // Try to get sequence-level embeddings (this might work with pooling enabled)
        if let seq_embeddings_ptr = llama_get_embeddings_seq(context, 0) {
            print("DEBUG: Retrieved sequence-level embeddings successfully")
            
            let embeddings = Array(UnsafeBufferPointer(start: seq_embeddings_ptr, count: n_embd))
            
            // Check if embeddings are valid (not all zeros)
            let non_zero_count = embeddings.filter { $0 != 0.0 }.count
            print("DEBUG: Non-zero embedding values: \(non_zero_count) out of \(n_embd)")
            
            if non_zero_count > 0 {
                // L2 normalize and return
                let normalized = l2normalize(embeddings)
                let norm = sqrt(normalized.reduce(0) { $0 + $1 * $1 })
                print("DEBUG: L2 norm of final embedding: \(norm)")
                return normalized
            }
        }
        
        // 6. APPROACH 2: Fall back to manual mean pooling if sequence embeddings don't work
        print("DEBUG: Falling back to manual mean pooling")
        
        guard let all_token_embeddings_ptr = llama_get_embeddings(context) else {
            print("Error: Failed to retrieve token embeddings pointer.")
            throw LlamaError.embeddingGenerationFailed
        }
        
        print("DEBUG: Retrieved token embeddings pointer successfully")
        
        let n_tokens = Int(batch.n_tokens)
        
        // Check if we have valid embeddings
        var non_zero_count = 0
        for i in 0..<(n_tokens * n_embd) {
            if all_token_embeddings_ptr[i] != 0.0 {
                non_zero_count += 1
            }
        }
        print("DEBUG: Non-zero token embedding values: \(non_zero_count) out of \(n_tokens * n_embd)")
        
        if non_zero_count == 0 {
            print("ERROR: All embedding values are zero - check model configuration")
            throw LlamaError.embeddingGenerationFailed
        }
        
        // 7. Perform Mean Pooling manually
        var mean_embedding = [Float](repeating: 0.0, count: n_embd)
        for i in 0..<n_embd {
            var dim_sum: Float = 0.0
            for j in 0..<n_tokens {
                dim_sum += all_token_embeddings_ptr[j * n_embd + i]
            }
            mean_embedding[i] = dim_sum / Float(n_tokens)
        }
        
        print("DEBUG: Manual mean pooling completed")
        
        // 8. L2 Normalize the final embedding vector
        let normalized_embedding = l2normalize(mean_embedding)
        
        let norm = sqrt(normalized_embedding.reduce(0) { $0 + $1 * $1 })
        print("DEBUG: L2 norm of final embedding: \(norm)")
        
        return normalized_embedding
    }
    
    /// Generates embeddings for multiple texts in a single batch operation.
    /// This is significantly more efficient than calling generateEmbedding multiple times.
    func generateEmbeddings(for texts: [String]) throws -> [[Float]] {
        guard !texts.isEmpty else { return [] }
        
        print("DEBUG: Starting batch embedding for \(texts.count) texts")
        
        // 1. Clear previous batch data
        llama_batch_clear(&batch)
        
        var sequenceIds: [Int32] = []
        var totalTokens = 0
        
        // 2. Tokenize all texts and add them to the batch
        for (sequenceIndex, text) in texts.enumerated() {
            let prefixedText = "search_query: " + text
            
            let tokens: [llama_token]
            do {
                tokens = try tokenize(text: prefixedText, add_bos: true)
            } catch {
                print("Warning: Failed to tokenize text at index \(sequenceIndex), skipping")
                continue
            }
            
            guard !tokens.isEmpty else {
                print("Warning: Empty tokens for text at index \(sequenceIndex), skipping")
                continue
            }
            
            // Check if adding these tokens would exceed capacity
            if totalTokens + tokens.count > 4096 {
                print("Warning: Adding sequence \(sequenceIndex) would exceed batch capacity. Stopping at \(totalTokens) tokens.")
                break
            }
            
            // Add tokens to the batch, assigning a unique sequence ID to each text
            let sequenceId = Int32(sequenceIndex)
            for (tokenIndex, token) in tokens.enumerated() {
                llama_batch_add(&batch, token, Int32(tokenIndex), [sequenceId], true)
            }
            
            sequenceIds.append(sequenceId)
            totalTokens += tokens.count
            
            print("DEBUG: Added sequence \(sequenceId) with \(tokens.count) tokens")
        }
        
        batch.n_tokens = Int32(totalTokens)
        
        guard !sequenceIds.isEmpty else {
            print("Error: No valid sequences to process")
            throw LlamaError.embeddingGenerationFailed
        }
        
        print("DEBUG: Batch prepared with \(batch.n_tokens) total tokens across \(sequenceIds.count) sequences")
        
        // 3. Run encoding once for the entire batch
        let encode_result = llama_encode(context, batch)
        if encode_result != 0 {
            print("Error: llama_encode failed with code: \(encode_result)")
            throw LlamaError.embeddingGenerationFailed
        }
        
        print("DEBUG: Batch encoding succeeded")
        
        // 4. Extract the embedding for each sequence
        var allEmbeddings: [[Float]] = []
        let n_embd = Int(llama_n_embd(model))
        
        for seq_id in sequenceIds {
            if let seq_embeddings_ptr = llama_get_embeddings_seq(context, seq_id) {
                let embedding = Array(UnsafeBufferPointer(start: seq_embeddings_ptr, count: n_embd))
                let normalized = l2normalize(embedding)
                allEmbeddings.append(normalized)
                print("DEBUG: Successfully extracted embedding for sequence \(seq_id)")
            } else {
                print("WARNING: Could not retrieve embedding for sequence \(seq_id)")
                // Return an empty embedding for this sequence to maintain array consistency
                allEmbeddings.append([Float](repeating: 0.0, count: n_embd))
            }
        }
        
        print("DEBUG: Batch embedding completed. Generated \(allEmbeddings.count) embeddings")
        return allEmbeddings
    }

    // MARK: - Private Helper Methods

    /// Tokenizes the input text using the loaded Llama model with improved memory safety.
    private func tokenize(text: String, add_bos: Bool) throws -> [llama_token] {
        // Input validation
        guard !text.isEmpty else {
            throw LlamaError.tokenizationFailed
        }
        
        let utf8Count = text.utf8.count
        let bufferSize = max(2048, utf8Count * 4)  // More generous buffer
        
        var tokens = [llama_token](repeating: 0, count: bufferSize)

        print("--- Tokenizing ---")
        print("Text to tokenize: '\(text)'")
        print("Buffer size: \(bufferSize)")
        
        // Get the model's vocabulary
        let vocab = llama_model_get_vocab(model)
        
        let tokenCount = text.withCString { cString in
            llama_tokenize(
                vocab,
                cString,
                Int32(utf8Count),
                &tokens,
                Int32(bufferSize),
                add_bos,
                true // special: process special tokens
            )
        }

        // Improved error handling
        if tokenCount < 0 {
            print("Error: llama_tokenize failed with code \(tokenCount)")
            throw LlamaError.tokenizationFailed
        }
        
        if tokenCount == 0 {
            print("Warning: Tokenization produced no tokens")
            throw LlamaError.tokenizationFailed
        }

        // Safely return only the valid tokens
        let validTokenCount = min(Int(tokenCount), bufferSize)
        return Array(tokens.prefix(validTokenCount))
    }
    
    /// Computes the L2 norm of a vector and normalizes it.
    func l2normalize(_ vector: [Float]) -> [Float] {
        let norm = sqrt(vector.reduce(0) { $0 + $1 * $1 })
        
        // Avoid division by zero
        guard norm > Float.ulpOfOne else {
            print("WARNING: Vector has zero or near-zero norm, returning zero vector")
            return vector
        }
        
        return vector.map { $0 / norm }
    }
}
