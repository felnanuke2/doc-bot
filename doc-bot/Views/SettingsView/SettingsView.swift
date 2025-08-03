//
//  LanguageSelectionView.swift
//  Doc Bot
//
//  Created by LUIZ FELIPE ALVES LIMA on 03/08/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "en"
    @AppStorage("selectedTheme") private var selectedTheme: String = "system"
    
    private let availableLanguages = [
        LanguageOption(code: "en", name: "English", flag: "🇺🇸"),
        LanguageOption(code: "es", name: "Español", flag: "🇪🇸"),
        LanguageOption(code: "pt-BR", name: "Português", flag: "🇧🇷")
    ]
    
    private let availableThemes = [
        ThemeOption(code: "system", name: LocalizedString.themeSystem, icon: "circle.lefthalf.filled"),
        ThemeOption(code: "light", name: LocalizedString.themeLight, icon: "sun.max"),
        ThemeOption(code: "dark", name: LocalizedString.themeDark, icon: "moon")
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text(LocalizedString.languagesSectionTitle)) {
                    ForEach(availableLanguages, id: \.code) { language in
                        LanguageRow(
                            language: language,
                            isSelected: selectedLanguage == language.code
                        ) {
                            selectLanguage(language.code)
                        }
                    }
                }
                
                Section(header: Text(LocalizedString.themeSectionTitle)) {
                    ForEach(availableThemes, id: \.code) { theme in
                        ThemeRow(
                            theme: theme,
                            isSelected: selectedTheme == theme.code
                        ) {
                            selectTheme(theme.code)
                        }
                    }
                }
                
                Section(footer: Text(LocalizedString.languagesFooterNote)) {
                    EmptyView()
                }
            }
            .navigationTitle(LocalizedString.navConfigurations)
        }
    }
    
    private func selectLanguage(_ code: String) {
        selectedLanguage = code
        // Update the app's locale
        UserDefaults.standard.set([code], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
    
    private func selectTheme(_ code: String) {
        selectedTheme = code
    }
}

struct LanguageOption {
    let code: String
    let name: String
    let flag: String
}

struct ThemeOption {
    let code: String
    let name: String
    let icon: String
}

struct LanguageRow: View {
    let language: LanguageOption
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(language.flag)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(language.code.uppercased())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ThemeRow: View {
    let theme: ThemeOption
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: theme.icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(theme.code.uppercased())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsView()
}
