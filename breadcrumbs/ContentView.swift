//
//  ContentView.swift
//  breadcrumbs
//
//  System Diagnostics Chatbot - Main View
//

import SwiftUI

struct ContentView: View {
    @State private var showingSettings = false
    @State private var apiKey: String?

    private let keychain = KeychainHelper.shared

    var body: some View {
        VStack {
            if let key = apiKey, !key.isEmpty {
                // Show chat interface
                ChatView(apiKey: key)
            } else {
                // Show welcome screen if no API key
                WelcomeView(showingSettings: $showingSettings)
            }
        }
        .sheet(isPresented: $showingSettings, onDismiss: {
            // Reload API key when settings closes
            loadAPIKey()
        }) {
            SettingsView()
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
        .onAppear {
            loadAPIKey()
        }
    }

    private func loadAPIKey() {
        apiKey = keychain.get(forKey: KeychainHelper.openAIAPIKey)
    }
}

// MARK: - Welcome View

struct WelcomeView: View {
    @Binding var showingSettings: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "stethoscope")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            Text("Welcome to System Diagnostics")
                .font(.title)
                .fontWeight(.bold)

            Text("Your AI-powered system diagnostic assistant")
                .font(.title3)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(
                    icon: "network",
                    title: "Network Diagnostics",
                    description: "Check VPN status and connectivity"
                )
                FeatureRow(
                    icon: "shield.checkered",
                    title: "Security Analysis",
                    description: "Analyze system security settings"
                )
                FeatureRow(
                    icon: "cpu",
                    title: "System Health",
                    description: "Monitor performance and resources"
                )
            }
            .padding()

            Button {
                showingSettings = true
            } label: {
                HStack {
                    Image(systemName: "key.fill")
                    Text("Setup OpenAI API Key")
                }
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
}
