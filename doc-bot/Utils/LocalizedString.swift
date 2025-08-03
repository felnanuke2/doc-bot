import Foundation

/// Helper struct for localized strings
enum LocalizedString {
    // MARK: - Navigation
    static let navDocuments = NSLocalizedString("nav.documents", comment: "Documents navigation title")
    static let navModels = NSLocalizedString("nav.models", comment: "Models navigation title")
    static let navChat = NSLocalizedString("nav.chat", comment: "Chat navigation title")
    static let navConfigurations = NSLocalizedString("nav.configurations", comment: "Configurations navigation title")
    
    // MARK: - Tab Labels
    static let tabImport = NSLocalizedString("tab.import", comment: "Import tab label")
    static let tabModels = NSLocalizedString("tab.models", comment: "Models tab label")
    static let tabConfigurations = NSLocalizedString("tab.configurations", comment: "Configurations tab label")
    
    // MARK: - Buttons
    static let buttonImport = NSLocalizedString("button.import", comment: "Import button label")
    static let buttonOK = NSLocalizedString("button.ok", comment: "OK button")
    static let buttonStop = NSLocalizedString("button.stop", comment: "Stop button")
    static let buttonSend = NSLocalizedString("button.send", comment: "Send button")
    
    // MARK: - Documents View
    static let documentsEmptyTitle = NSLocalizedString("documents.empty.title", comment: "Empty state title")
    static let documentsEmptySubtitle = NSLocalizedString("documents.empty.subtitle", comment: "Empty state subtitle")
    static let documentsImporting = NSLocalizedString("documents.importing", comment: "Importing progress text")
    static let documentsLoading = NSLocalizedString("documents.loading", comment: "Loading documents text")
    static let documentsUntitled = NSLocalizedString("documents.untitled", comment: "Untitled document name")
    
    static func conversationsCount(_ count: Int) -> String {
        return String(format: NSLocalizedString("documents.conversations.count", comment: "Conversations count"), count)
    }
    
    // MARK: - Models View
    static let modelsActiveTitle = NSLocalizedString("models.active.title", comment: "Active model section title")
    static let modelsAvailableTitle = NSLocalizedString("models.available.title", comment: "Available models section title")
    static let modelsNoModel = NSLocalizedString("models.no.model", comment: "No model downloaded message")
    static let modelsReady = NSLocalizedString("models.ready", comment: "Model ready status")
    
    static func modelsProgress(_ progress: Double) -> String {
        return String(format: NSLocalizedString("models.progress.format", comment: "Progress percentage"), progress * 100)
    }
    
    // MARK: - Model Loading
    static let modelInitializing = NSLocalizedString("model.initializing", comment: "Model initializing")
    static let modelDownloading = NSLocalizedString("model.downloading", comment: "Model downloading")
    static let modelDownloadFailed = NSLocalizedString("model.download.failed", comment: "Download failed")
    static let modelDownloadComplete = NSLocalizedString("model.download.complete", comment: "Download complete")
    
    // MARK: - Chat
    static let chatWelcome = NSLocalizedString("chat.welcome", comment: "Chat welcome message")
    static let chatTyping = NSLocalizedString("chat.typing", comment: "Typing indicator")
    static let chatPlaceholder = NSLocalizedString("chat.placeholder", comment: "Message input placeholder")
    
    // MARK: - Conversations
    static let conversationDelete = NSLocalizedString("conversation.delete", comment: "Delete conversation action")
    static let conversationDeleteTitle = NSLocalizedString("conversation.delete.title", comment: "Delete conversation alert title")
    static let conversationDeleteMessage = NSLocalizedString("conversation.delete.message", comment: "Delete conversation alert message")
    static let conversationNew = NSLocalizedString("conversation.new", comment: "New conversation title")
    static let conversationNoMessages = NSLocalizedString("conversation.no.messages", comment: "No messages placeholder")
    static let conversationsTitle = NSLocalizedString("conversations.title", comment: "Conversations list title")
    static let conversationsNewChat = NSLocalizedString("conversations.new.chat", comment: "New chat button")
    static let conversationsLoading = NSLocalizedString("conversations.loading", comment: "Loading conversations message")
    static let conversationsEmptyTitle = NSLocalizedString("conversations.empty.title", comment: "Empty conversations title")
    static let conversationsEmptySubtitle = NSLocalizedString("conversations.empty.subtitle", comment: "Empty conversations subtitle")
    static let buttonCancel = NSLocalizedString("button.cancel", comment: "Cancel button")
    static let buttonDismiss = NSLocalizedString("button.dismiss", comment: "Dismiss button")
    
    // MARK: - Languages
    static let languagesSectionTitle = NSLocalizedString("languages.section.title", comment: "Languages section title")
    static let languagesFooterNote = NSLocalizedString("languages.footer.note", comment: "Languages footer note")
    
    // MARK: - Theme
    static let themeSectionTitle = NSLocalizedString("theme.section.title", comment: "Theme section title")
    static let themeLight = NSLocalizedString("theme.light", comment: "Light theme")
    static let themeDark = NSLocalizedString("theme.dark", comment: "Dark theme")
    static let themeSystem = NSLocalizedString("theme.system", comment: "System theme")
    
    // MARK: - Alerts
    static let alertErrorTitle = NSLocalizedString("alert.error.title", comment: "Error alert title")
    static let alertErrorMessage = NSLocalizedString("alert.error.message", comment: "Error alert message")
    
    // MARK: - Accessibility
    static let accessibilityDelete = NSLocalizedString("accessibility.delete", comment: "Delete accessibility label")
    static let accessibilityDownload = NSLocalizedString("accessibility.download", comment: "Download accessibility label")
    static let accessibilitySidebar = NSLocalizedString("accessibility.sidebar", comment: "Sidebar accessibility label")
}
