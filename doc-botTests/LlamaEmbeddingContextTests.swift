import XCTest
@testable import doc_bot

class LlamaEmbeddingContextTests: XCTestCase {
    var context: LlamaEmbeddingContext?
    let dummyModelPath = "/Users/luizfelipealveslima/Library/Developer/CoreSimulator/Devices/2B358344-953D-4B94-8FFE-6951EFC9CA93/data/Containers/Data/Application/9C5BB77F-C5FB-4148-83EB-AD9C66C4BD01/Documents/nomic-embed-text-v1.5.Q4_0.gguf" // Update with a valid path for real tests

    override func setUpWithError() throws {
        // Create a dummy file to simulate model existence
        FileManager.default.createFile(atPath: dummyModelPath, contents: Data(), attributes: nil)
        // Try to create context (will fail with dummy file, but tests error handling)
        do {
            context = try LlamaEmbeddingContext.createContext(path: dummyModelPath)
        } catch {
            context = nil
        }
    }

    override func tearDownWithError() throws {
        // Remove dummy file
        try? FileManager.default.removeItem(atPath: dummyModelPath)
        context = nil
    }

    func testCreateContextWithInvalidPathThrows() {
        XCTAssertThrowsError(try LlamaEmbeddingContext.createContext(path: "/invalid/path/model.gguf"))
    }

    func testGenerateEmbeddingWithEmptyTextThrows() async {
        guard let context = context else { return }
        do {
            _ = try await context.generateEmbedding(for: "   ")
            XCTFail("Expected error was not thrown")
        } catch {
            // Success: error thrown
        }
    }

    //test if embedding is generated correctly
    func testGenerateEmbeddingWithValidText() async {
        guard let context = context else { return }
        do {
            let embedding = try await context.generateEmbedding(for: "Hello, world!")
            XCTFail("Unexpected error: \(embedding)")   
            XCTAssertEqual(embedding.count, 512) // Assuming the model generates 512-dimensional embeddings
            XCTAssertFalse(embedding.contains(where: { $0.isNaN || $0.isInfinite
            }), "Embedding contains invalid values")
        } catch {
            XCTFail("Unexpected error: \(error)")   
        }
    }
}
