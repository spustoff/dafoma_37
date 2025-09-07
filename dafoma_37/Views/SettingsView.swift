//
//  SettingsView.swift
//  TaskOrbit Ano
//
//  Created by Assistant on 9/6/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var dataService: DataService
    @State private var showingDeleteAccountAlert = false
    @State private var showingResetDataAlert = false
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var exportedData: Data?
    
    var body: some View {
        NavigationView {
            List {
                
                // App Preferences
                preferencesSection
                
                // Data Management
                dataSection
                
                // About
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This will permanently delete your account and all associated data. This action cannot be undone.")
        }
        .alert("Reset All Data", isPresented: $showingResetDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                dataService.resetAllData()
            }
        } message: {
            Text("This will delete all your tasks, projects, and settings. This action cannot be undone.")
        }
        .sheet(isPresented: $showingExportSheet) {
            if let data = exportedData {
                ShareSheet(items: [data])
            }
        }
        .sheet(isPresented: $showingImportSheet) {
            DocumentPicker { data in
                _ = dataService.importData(data)
            }
        }
    }
    
    private var profileSection: some View {
        Section {
            HStack(spacing: 16) {
                Circle()
                    .fill(Color.taskOrbitOrange)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(dataService.currentUser.initials)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(dataService.currentUser.displayName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    Text(dataService.currentUser.email)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondaryText)
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.taskOrbitOrange)
                            Text("\(dataService.currentUser.coinsEarned) coins")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondaryText)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.profitGreen)
                            Text("\(dataService.currentUser.tasksCompleted) tasks")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondaryText)
                        }
                    }
                }
                
                Spacer()
                
                Button(action: {
                    // Edit profile action
                }) {
                    Text("Edit")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.taskOrbitOrange)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.taskOrbitOrange.opacity(0.1))
                        .cornerRadius(16)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var preferencesSection: some View {
        Section("Preferences") {
            HStack {
                Image(systemName: "moon.fill")
                    .foregroundColor(.taskOrbitOrange)
                    .frame(width: 24)
                
                Text("Dark Mode")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { dataService.currentUser.preferences.enableDarkMode },
                    set: { newValue in
                        var updatedUser = dataService.currentUser
                        updatedUser.preferences.enableDarkMode = newValue
                        dataService.updateCurrentUser(updatedUser)
                    }
                ))
                .tint(.taskOrbitOrange)
            }
            
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(.taskOrbitOrange)
                    .frame(width: 24)
                
                Text("Default Project View")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Picker("View", selection: Binding(
                    get: { dataService.currentUser.preferences.defaultProjectView },
                    set: { newValue in
                        var updatedUser = dataService.currentUser
                        updatedUser.preferences.defaultProjectView = newValue
                        dataService.updateCurrentUser(updatedUser)
                    }
                )) {
                    ForEach(UserPreferences.ProjectView.allCases, id: \.self) { view in
                        Text(view.rawValue).tag(view)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .tint(.taskOrbitOrange)
            }
            
            HStack {
                Image(systemName: "dollarsign.circle")
                    .foregroundColor(.taskOrbitOrange)
                    .frame(width: 24)
                
                Text("Show Budget Warnings")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { dataService.currentUser.preferences.showBudgetWarnings },
                    set: { newValue in
                        var updatedUser = dataService.currentUser
                        updatedUser.preferences.showBudgetWarnings = newValue
                        dataService.updateCurrentUser(updatedUser)
                    }
                ))
                .tint(.taskOrbitOrange)
            }
            
            HStack {
                Image(systemName: "banknote")
                    .foregroundColor(.taskOrbitOrange)
                    .frame(width: 24)
                
                Text("Preferred Currency")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Picker("Currency", selection: Binding(
                    get: { dataService.currentUser.preferences.preferredCurrency },
                    set: { newValue in
                        var updatedUser = dataService.currentUser
                        updatedUser.preferences.preferredCurrency = newValue
                        dataService.updateCurrentUser(updatedUser)
                    }
                )) {
                    Text("USD").tag("USD")
                    Text("EUR").tag("EUR")
                    Text("GBP").tag("GBP")
                    Text("JPY").tag("JPY")
                }
                .pickerStyle(MenuPickerStyle())
                .tint(.taskOrbitOrange)
            }
        }
    }
    
    private var notificationsSection: some View {
        Section("Notifications") {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.taskOrbitOrange)
                    .frame(width: 24)
                
                Text("Enable Notifications")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { dataService.currentUser.preferences.enableNotifications },
                    set: { newValue in
                        var updatedUser = dataService.currentUser
                        updatedUser.preferences.enableNotifications = newValue
                        dataService.updateCurrentUser(updatedUser)
                    }
                ))
                .tint(.taskOrbitOrange)
            }
            
            NavigationLink(destination: WorkingHoursView()) {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.taskOrbitOrange)
                        .frame(width: 24)
                    
                    Text("Working Hours")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                    
                    Text("\(dataService.currentUser.preferences.workingHoursStart):00 - \(dataService.currentUser.preferences.workingHoursEnd):00")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondaryText)
                }
            }
        }
    }
    
    private var dataSection: some View {
        Section("Data Management") {
            
            Button(action: {
                showingResetDataAlert = true
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.budgetWarning)
                        .frame(width: 24)
                    
                    Text("Reset All Data")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.budgetWarning)
                    
                    Spacer()
                }
            }
        }
    }
    
    private var aboutSection: some View {
        Section("About") {
            NavigationLink(destination: AboutView()) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.taskOrbitOrange)
                        .frame(width: 24)
                    
                    Text("About TaskOrbit Ano")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                }
            }
            
            NavigationLink(destination: PrivacyPolicyView()) {
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundColor(.taskOrbitOrange)
                        .frame(width: 24)
                    
                    Text("Privacy Policy")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                }
            }
            
            NavigationLink(destination: TermsOfServiceView()) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.taskOrbitOrange)
                        .frame(width: 24)
                    
                    Text("Terms of Service")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                }
            }
        }
    }
    
    private var dangerZoneSection: some View {
        Section("Danger Zone") {
            Button(action: {
                showingDeleteAccountAlert = true
            }) {
                HStack {
                    Image(systemName: "person.crop.circle.badge.minus")
                        .foregroundColor(.lossRed)
                        .frame(width: 24)
                    
                    Text("Delete Account")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.lossRed)
                    
                    Spacer()
                }
            }
        }
    }
    
    private func deleteAccount() {
        // In a real app, this would call an API to delete the account
        // For now, we'll just reset all data and show a message
        dataService.resetAllData()
        
        // Show success message or navigate to login screen
        print("Account deleted successfully")
    }
}

// MARK: - Supporting Views
struct WorkingHoursView: View {
    @EnvironmentObject private var dataService: DataService
    @State private var startHour: Int
    @State private var endHour: Int
    
    init() {
        let currentUser = DataService.shared.currentUser
        _startHour = State(initialValue: currentUser.preferences.workingHoursStart)
        _endHour = State(initialValue: currentUser.preferences.workingHoursEnd)
    }
    
    var body: some View {
        Form {
            Section("Working Hours") {
                Picker("Start Time", selection: $startHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text("\(hour):00").tag(hour)
                    }
                }
                
                Picker("End Time", selection: $endHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text("\(hour):00").tag(hour)
                    }
                }
            }
        }
        .navigationTitle("Working Hours")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    var updatedUser = dataService.currentUser
                    updatedUser.preferences.workingHoursStart = startHour
                    updatedUser.preferences.workingHoursEnd = endHour
                    dataService.updateCurrentUser(updatedUser)
                }
                .font(.system(size: 16, weight: .semibold))
            }
        }
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "rocket.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.taskOrbitOrange)
                    
                    Text("TaskOrbit Ano")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primaryText)
                    
                    Text("Version 1.0.0")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("About")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    Text("TaskOrbit Ano is a comprehensive task and project management app that combines productivity tracking with financial insights. Designed to help individuals and teams manage their work more effectively while keeping track of budgets and costs.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.primaryText)
                        .lineSpacing(4)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Features")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(icon: "list.bullet", title: "Task Management", description: "Create, organize, and track tasks with priorities and due dates")
                        FeatureRow(icon: "dollarsign.circle", title: "Financial Tracking", description: "Monitor budgets and costs for projects and tasks")
                        FeatureRow(icon: "person.3", title: "Team Collaboration", description: "Work together with team members and share projects")
                        FeatureRow(icon: "chart.bar", title: "Analytics", description: "Visualize progress and performance with detailed charts")
                        FeatureRow(icon: "star", title: "Gamification", description: "Earn coins and rewards for completing tasks")
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.taskOrbitOrange)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondaryText)
                    .lineSpacing(2)
            }
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Privacy Policy")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primaryText)
                
                Group {
                    PolicySection(
                        title: "Data Collection",
                        content: "TaskOrbit Ano collects only the data necessary to provide our services. This includes task information, project details, and user preferences that you provide."
                    )
                    
                    PolicySection(
                        title: "Data Usage",
                        content: "Your data is used solely to provide the task management and analytics features of the app. We do not share your personal data with third parties without your consent."
                    )
                    
                    PolicySection(
                        title: "Data Storage",
                        content: "All data is stored locally on your device and in secure cloud services when you choose to sync across devices. You have full control over your data."
                    )
                    
                    PolicySection(
                        title: "Your Rights",
                        content: "You have the right to access, modify, or delete your data at any time through the app's settings. You can also export your data or request account deletion."
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Terms of Service")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primaryText)
                
                Group {
                    PolicySection(
                        title: "Acceptance of Terms",
                        content: "By using TaskOrbit Ano, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the app."
                    )
                    
                    PolicySection(
                        title: "Use of Service",
                        content: "TaskOrbit Ano is provided for personal and commercial use in managing tasks and projects. You may not use the service for any illegal or unauthorized purpose."
                    )
                    
                    PolicySection(
                        title: "User Content",
                        content: "You retain all rights to the content you create in TaskOrbit Ano. You are responsible for the accuracy and legality of your content."
                    )
                    
                    PolicySection(
                        title: "Limitation of Liability",
                        content: "TaskOrbit Ano is provided 'as is' without warranties. We are not liable for any damages arising from the use of the app."
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PolicySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primaryText)
            
            Text(content)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.primaryText)
                .lineSpacing(4)
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    let onDocumentPicked: (Data) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            if let data = try? Data(contentsOf: url) {
                parent.onDocumentPicked(data)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(DataService.shared)
}
