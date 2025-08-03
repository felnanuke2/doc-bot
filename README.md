# 🚧 Project Status: Under Development 🚧

# doc-bot

## Overview

doc-bot is a fully offline Retrieval-Augmented Generation (RAG) app targeting iOS and iPadOS. The goal is to let you chat with your own PDF documents using AI, with all processing done locally and only using downloaded models—no internet connection or cloud APIs required. The app uses SwiftUI as its interface builder for a modern, native experience. Import a PDF, ask questions, and get answers powered by local language models and embeddings.

## Features

- **Fully Offline RAG**: All retrieval, embedding, and LLM inference is performed on-device using only downloaded models. No cloud or online API calls.
- **Offline RAG Chat**: Chat with your imported PDF documents using AI, with all processing done locally.
- **Multiple Conversations**: Create and manage multiple conversation threads for each document, with automatic subject generation.
- **Conversation Management**: Switch between conversations with a side drawer interface, view conversation history, and manage chat sessions.
- **PDF Import**: Uses Apple PDFKit to extract text from PDF files with progress tracking and error handling.
- **Chunking, Embedding & Similarity Search**: Utilizes Apple's NaturalLanguage framework to split text into chunks, generate embeddings, and perform similarity search—all on-device, without Faiss or external libraries.
- **Local Embedding Storage**: Embeddings are saved as JSON files in the app support directory using FileManager for fast, private retrieval.
- **CoreData Persistence**: Documents, conversations, and messages are stored using CoreData for reliability and offline access with cascade deletion support.
- **Local LLM Inference**: Answers are generated using the Qwen2-0.5B.Q4_K_M model (or other supported GGUF models) via llama.cpp integration.
- **Modern SwiftUI UI**: Clean, native interface with improved animations, typing indicators, and message bubbles.
- **Internationalization**: Multi-language support with English, Spanish, and Portuguese (Brazil) localizations.
- **Customizable Themes**: Light, dark, and system theme options for personalized user experience.
- **Settings & Configuration**: Dedicated settings view for language selection, theme customization, and app preferences.

## How It Works

1. **Import PDF**: Select a PDF to import. The app extracts its text using PDFKit with real-time progress tracking.
2. **Chunking**: The text is split into manageable chunks using Apple's NaturalLanguage framework, targeting optimal size for embeddings.
3. **Embedding Generation**: Each chunk is embedded using a local embedding model (e.g., nomic-embed-text-v1.5 or bge-small-en-v1.5, in GGUF format).
4. **Vector Storage & Search**: Embeddings are stored as JSON files in the app support directory using FileManager, and similarity search is performed using Apple's NaturalLanguage framework to find relevant chunks—no Faiss required.
5. **Persistence**: All documents, conversations, and messages are saved using CoreData for offline access and reliability.
6. **Multiple Conversations**: Create multiple conversation threads for each document, with automatic subject generation based on the first user message.
7. **Chat Interface**: When you ask a question, the app finds the most relevant chunks using Apple's NaturalLanguage similarity search and uses a local LLM (Qwen2-0.5B.Q4_K_M or similar) via llama.cpp to generate an answer.
8. **Conversation Management**: Switch between conversations using the side drawer, view conversation history, and manage your chat sessions.


## Supported Models

- **LLMs**: Qwen2-0.5B.Q4_K_M (default), chosen for its small download size and efficient memory allocation on smartphones. While not as powerful as cloud models like Claude Sonnet 4, Qwen2 provides satisfactory results and works fully offline on-device, making it ideal for mobile use. Other supported models include Phi Mini 3 Q4, TinyLlama, Mistral, OpenHermes, and others in GGUF format.
- **Embedding Models**: Support for various embedding models in GGUF format including nomic-embed-text-v1.5 and bge-small-en-v1.5 for generating document chunk embeddings.

## User Interface

- **Tabbed Interface**: Easy navigation between Documents, Models, and Settings
- **Document Management**: Import, view, and organize your PDF documents with enhanced UI
- **Chat Interface**: Modern message bubbles with user/assistant differentiation and typing indicators
- **Conversation Drawer**: Side panel for switching between multiple conversations per document
- **Progress Tracking**: Real-time progress indicators for document import and model downloads
- **Responsive Design**: Optimized for both iPhone and iPad with adaptive layouts

## Internationalization & Accessibility

- **Multi-language Support**: Full localization for English, Spanish, and Portuguese (Brazil)
- **Theme Options**: Light, dark, and system-adaptive themes
- **Accessibility**: Proper accessibility labels and VoiceOver support
- **Localized Strings**: All user-facing text is properly localized for international users

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
4. **Download a model from the Models tab** (Qwen2-0.5B.Q4_K_M recommended for first-time users)
5. **Import a PDF from the Documents tab**
6. **Start chatting with your document!**
7. **Create multiple conversations** using the conversation drawer for different topics
8. **Customize your experience** in the Settings tab with themes and language preferences

## Assets & Screenshots

<p align="center">
  <img src="images/Screenshot%202025-07-25%20at%2014.45.27.png" alt="App Screenshot" width="300" />
</p>

<p align="center">
  <img src="images/Simulator%20Screenshot%20-%20iPhone%2016%20Pro%20-%202025-07-25%20at%2018.18.46.png" alt="Simulator Screenshot 1" width="300" />
  <img src="images/Simulator%20Screenshot%20-%20iPhone%2016%20Pro%20-%202025-07-25%20at%2018.18.54.png" alt="Simulator Screenshot 2" width="300" />
  <img src="images/Simulator%20Screenshot%20-%20iPhone%2016%20Pro%20-%202025-07-25%20at%2018.20.06.png" alt="Simulator Screenshot 3" width="300" />
  <img src="images/Simulator%20Screenshot%20-%20iPhone%2016%20Pro%20-%202025-07-25%20at%2018.20.51.png" alt="Simulator Screenshot 4" width="300" />
</p>


<p align="center">
  <a href="https://drive.google.com/file/d/1MB253zuVxXu-hbVjtgr3nbadbO-Nu4n2/view?usp=sharing">▶️ Watch Demo Video (Google Drive)</a>
</p>


## Architecture

- **SwiftUI** for UI with component-based architecture and reusable views
- **PDFKit** for PDF text extraction with progress tracking
- **NaturalLanguage** for chunking, embedding, and similarity search
- **CoreData** for persistence of documents, conversations, and messages with proper relationship management
- **llama.cpp** (via Swift bindings) for LLM and embedding inference (using Qwen2-0.5B.Q4_K_M by default for its small size and mobile suitability)
- **JSON (in App Support via FileManager)** for vector storage
- **Combine/Factory** for dependency injection and state management
- **Modular Design**: Separated view components, repositories, and infrastructure layers for maintainability

## New in This Version

- ✨ **Multiple Conversations**: Create and manage multiple conversation threads per document
- 🌍 **Internationalization**: Support for English, Spanish, and Portuguese (Brazil)
- 🎨 **Theme Support**: Light, dark, and system-adaptive themes
- 🗂️ **Better Organization**: Restructured UI components for better maintainability
- 📱 **Enhanced UX**: Improved animations, loading states, and user feedback
- 🔄 **Conversation Switching**: Side drawer for easy conversation navigation
- 📊 **Progress Tracking**: Real-time progress for imports and downloads
- 🏗️ **Repository Pattern**: Better data management with repository abstraction
- 🧪 **Expanded Testing**: Comprehensive test coverage including integration and performance tests

## Extending & Customizing

- **Add New Models**: Update the `Models` list to include additional GGUF models for LLM and embedding
- **Custom Themes**: Extend the theme system with additional color schemes
- **New Languages**: Add more localizations by creating new `.lproj` folders
- **UI Components**: Leverage the modular component architecture to add new features
- **Repository Extensions**: Implement additional repositories for new data types
- **Embedding Models**: Swap out embedding or LLM models as needed for different use cases
- **Chunking Strategies**: Extend chunking or retrieval logic for specific document types

## License

MIT License. See [LICENSE](LICENSE) file for details.

## Credits

- [llama.cpp](https://github.com/ggerganov/llama.cpp)
- [Apple PDFKit](https://developer.apple.com/documentation/pdfkit)
- [Apple NaturalLanguage](https://developer.apple.com/documentation/naturallanguage)
- [HuggingFace](https://huggingface.co/) for model hosting

---

*doc-bot: Your offline, private PDF AI chat companion.*
