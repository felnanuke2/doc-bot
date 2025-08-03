# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased] - 2025-08-03

### 🚀 Major Features Added

- **Multiple Conversations per Document**: Users can now create and manage multiple conversation threads for each imported PDF document
- **Conversation Management Interface**: Added side drawer navigation for switching between different conversations
- **Internationalization (i18n)**: Full localization support for English, Spanish, and Portuguese (Brazil) languages
- **Theme System**: Added customizable themes with support for light, dark, and system-adaptive color schemes
- **Enhanced Progress Tracking**: Real-time progress indicators for document imports and model downloads

### ✨ New Features

- **Automatic Subject Generation**: Conversations now automatically generate subjects based on the first user message
- **Conversation History**: View and manage conversation history with timestamps and message previews
- **Settings View**: Dedicated settings interface for language selection, theme customization, and app preferences
- **Enhanced UI Components**: Modular component architecture with reusable view elements
- **Repository Pattern**: Improved data management with abstracted repository layer
- **Comprehensive Testing**: Added integration tests, performance tests, and expanded unit test coverage

### 🔧 Improvements

#### User Interface
- **Modern Message Bubbles**: Enhanced chat interface with improved message styling and user/assistant differentiation
- **Typing Indicators**: Visual feedback when the assistant is generating responses
- **Responsive Design**: Optimized layouts for both iPhone and iPad devices
- **Better Loading States**: Improved loading indicators and user feedback throughout the app
- **Enhanced Animations**: Smoother transitions and micro-interactions

#### Architecture & Code Quality
- **Modular File Structure**: Reorganized codebase with better separation of concerns
- **Component-Based Architecture**: Separated UI components for better maintainability
- **Repository Abstraction**: Cleaner data layer with repository pattern implementation
- **Dependency Injection**: Improved dependency management and testability
- **Error Handling**: Enhanced error handling and user feedback

#### Data Management
- **Cascade Deletion**: Proper CoreData relationship management with cascade deletion support
- **Improved Data Models**: Enhanced entity relationships and data integrity
- **Better Persistence**: More robust data storage and retrieval mechanisms

### 🎨 UI/UX Enhancements

- **Document Management**: Enhanced document import interface with better visual feedback
- **Chat Interface**: Improved message layout with rounded corners and better spacing
- **Navigation**: Tabbed interface for easy navigation between Documents, Models, and Settings
- **Accessibility**: Proper accessibility labels and VoiceOver support
- **Visual Polish**: Updated color schemes, typography, and spacing throughout the app

### 🌍 Localization

- **Multi-language Support**: Added complete translations for:
  - English (en)
  - Spanish (es) 
  - Portuguese Brazil (pt-BR)
- **Localized Strings**: All user-facing text properly localized
- **Resource Management**: Organized localization files with proper string management

### 🏗️ Technical Improvements

#### Project Structure
- Reorganized Views into feature-based folders (`ChatView/`, `ImportedDocumentsView/`, `ModelsView/`, `SettingsView/`)
- Added dedicated `Resources/` folder for localization files
- Improved component separation with `Components/` subfolders
- Better utility organization with enhanced helper functions

#### Code Changes
- **Enhanced ViewModels**: Improved state management and business logic separation
- **Better Error Types**: More specific error handling for different failure scenarios
- **Improved Extensions**: Enhanced array utilities and helper methods
- **Cleaner Dependencies**: Better dependency injection and service management

#### Data Layer
- **Enhanced Repositories**: More robust data access patterns
- **Better CoreData Integration**: Improved entity management and relationship handling
- **Subject Generation**: Automatic conversation subject creation based on content

### 🧪 Testing Improvements

- **Expanded Test Coverage**: Added comprehensive test suites including:
  - Integration tests for end-to-end workflows
  - Performance tests for memory and speed optimization
  - Repository tests for data layer validation
  - Utility tests for helper functions
  - Enhanced unit tests for ViewModels
- **Better Test Structure**: Organized tests with proper mocking and setup
- **Mock Implementations**: Created mock repositories and services for isolated testing

### 📱 Model & AI Improvements

- **Updated Default Model**: Changed from Phi Mini 3 Q4 to Qwen2-0.5B.Q4_K_M for better mobile optimization
- **Enhanced Model Management**: Improved model download and selection interface
- **Better Embedding Support**: Enhanced support for various embedding models in GGUF format
- **Optimized Performance**: Better memory management for on-device AI processing

### 🔧 Configuration & Setup

- **Enhanced Build Configuration**: Updated Xcode project settings for multi-language support
- **Better App Configuration**: Improved app initialization and environment setup
- **Theme Management**: Added system-wide theme switching capabilities
- **User Preferences**: Persistent settings storage with UserDefaults integration

### 📚 Documentation Updates

- **Comprehensive README**: Extensively updated documentation with:
  - New feature descriptions
  - Enhanced "How It Works" section
  - Updated architecture information
  - Improved getting started guide
  - Extended customization and extension guidelines
- **Feature Documentation**: Detailed explanations of new capabilities
- **Technical Architecture**: Updated architecture diagrams and explanations

### 🐛 Bug Fixes

- Fixed memory leaks in animation components
- Improved error handling for model loading failures
- Enhanced data persistence reliability
- Better handling of edge cases in PDF parsing
- Fixed UI layout issues on different device sizes

### 🔄 Refactoring

- **Component Reorganization**: Moved from single-file components to organized folder structure
- **Code Deduplication**: Eliminated duplicate implementations of UI components
- **Better Separation of Concerns**: Improved architecture with cleaner boundaries
- **Enhanced Maintainability**: More modular and testable codebase

### ⚠️ Breaking Changes

- **File Structure Changes**: Significant reorganization of View files (existing imports may need updates)
- **ViewModel API Changes**: Some ViewModel interfaces have been updated for better conversation management
- **Settings Migration**: New settings system may require user preference reset

### 📋 Migration Notes

- Users may need to re-configure their theme and language preferences after update
- Existing conversations will be preserved but may show in the new conversation management interface
- Model downloads will be maintained but users should verify active model selection

---

### Development Notes

This release represents a significant evolution of doc-bot from a simple PDF chat application to a comprehensive, multi-conversation, internationalized document AI assistant. The focus has been on improving user experience, code maintainability, and preparing the foundation for future enhancements.

The modular architecture introduced in this version makes it easier to add new features, languages, and UI components while maintaining code quality and testability.
