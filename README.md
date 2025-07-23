# 🚧 Project Status: Under Development 🚧

# doc-bot

## Overview

doc-bot is a fully offline Retrieval-Augmented Generation (RAG) app targeting iOS and iPadOS. The goal is to let you chat with your own PDF documents using AI, with all processing done locally and only using downloaded models—no internet connection or cloud APIs required. The app uses SwiftUI as its interface builder for a modern, native experience. Import a PDF, ask questions, and get answers powered by local language models and embeddings.

## Features

- **Fully Offline RAG**: All retrieval, embedding, and LLM inference is performed on-device using only downloaded models. No cloud or online API calls.
- **Offline RAG Chat**: Chat with your imported PDF documents using AI, with all processing done locally.
- **PDF Import**: Uses Apple PDFKit to extract text from PDF files.
- **Chunking & Embedding**: Utilizes the NaturalLanguage framework to split text into chunks and generate embeddings.
- **Vector Similarity Search**: Uses Faiss for fast, approximate nearest neighbor search over embeddings.
- **Local Embedding Storage**: Embeddings are saved as JSON for fast, private retrieval.
- **CoreData Persistence**: Documents, conversations, and messages are stored using CoreData for reliability and offline access.
- **Local LLM Inference**: Answers are generated using the Phi Mini 3 Q4 model (or other supported GGUF models) via llama.cpp integration.
- **Modern SwiftUI UI**: Clean, native interface for document import, chat, and management.

## How It Works

1. **Import PDF**: Select a PDF to import. The app extracts its text using PDFKit.
2. **Chunking**: The text is split into manageable chunks using Apple's NaturalLanguage framework, targeting optimal size for embeddings.
3. **Embedding Generation**: Each chunk is embedded using a local embedding model (e.g., nomic-embed-text-v1.5 or bge-small-en-v1.5, in GGUF format).
4. **Vector Storage & Search**: Embeddings are stored locally as JSON files, and Faiss is used for fast approximate nearest neighbor search to find relevant chunks.
5. **Persistence**: All documents, conversations, and messages are saved using CoreData for offline access and reliability.
6. **Chat**: When you ask a question, the app finds the most relevant chunks using Faiss and uses a local LLM (Phi Mini 3 Q4 or similar) via llama.cpp to generate an answer.

## Supported Models

- **LLMs**: Phi Mini 3 Q4, TinyLlama, Mistral, OpenHermes, and others in GGUF format.
- **Embeddings**: nomic-embed-text-v1.5, bge-small-en-v1.5 (GGUF format).

## Privacy & Offline

- All processing (PDF parsing, chunking, embedding, LLM inference) is done on-device.
- No data is sent to external servers.

## Cons & Considerations

- **High Battery Consumption**: Local processing for chunking, embedding, and LLM inference can significantly increase battery usage, especially on mobile devices.
- **Device Heating**: Intensive computations may cause some devices to heat up during prolonged use.
- **Large Model Sizes**: Even "small" models can be 1GB or more, requiring substantial storage space on your device.

## Requirements

- iOS or iPadOS device with Apple Silicon recommended for best performance.
- Xcode for building and running the app.

## Getting Started

1. **Clone the repository**
2. **Open `doc-bot.xcodeproj` in Xcode**
3. **Build and run on your device or simulator**
4. **Import a PDF and start chatting!**

## Architecture

- **SwiftUI** for UI
- **PDFKit** for PDF text extraction
- **NaturalLanguage** for chunking
- **Faiss** for fast vector similarity search
- **CoreData** for persistence of documents, conversations, and messages
- **llama.cpp** (via Swift bindings) for LLM and embedding inference
- **JSON** for vector storage
- **Combine/Factory** for dependency injection and state management

## Extending & Customizing

- Add new GGUF models by updating the `Models` list.
- Swap out embedding or LLM models as needed.
- Extend chunking or retrieval logic for your use case.

## License

MIT License. See LICENSE file for details.

## Credits

- [llama.cpp](https://github.com/ggerganov/llama.cpp)
- [Apple PDFKit](https://developer.apple.com/documentation/pdfkit)
- [Apple NaturalLanguage](https://developer.apple.com/documentation/naturallanguage)
- [HuggingFace](https://huggingface.co/) for model hosting

---

*doc-bot: Your offline, private PDF AI chat companion.*
