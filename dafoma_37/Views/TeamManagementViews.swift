//
//  TeamManagementViews.swift
//  TaskOrbit Ano
//
//  Created by Assistant on 9/6/25.
//

import SwiftUI

struct InviteUserView: View {
    @EnvironmentObject private var teamViewModel: TeamViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var name = ""
    @State private var selectedRole: User.UserRole = .member
    
    var body: some View {
        NavigationView {
            Form {
                Section("User Information") {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section("Role") {
                    Picker("Role", selection: $selectedRole) {
                        ForEach(User.UserRole.allCases, id: \.self) { role in
                            Text(role.rawValue).tag(role)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Permissions") {
                    ForEach(selectedRole.permissions, id: \.self) { permission in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.profitGreen)
                            Text(permission.rawValue)
                                .font(.system(size: 14))
                        }
                    }
                }
            }
            .navigationTitle("Invite User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Invite") {
                        let newUser = User(
                            name: name.isEmpty ? email.components(separatedBy: "@").first?.capitalized ?? "User" : name,
                            email: email,
                            role: selectedRole
                        )
                        teamViewModel.addUser(newUser)
                        dismiss()
                    }
                    .disabled(email.isEmpty)
                    .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
}

struct UserDetailView: View {
    let user: User
    @EnvironmentObject private var teamViewModel: TeamViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // User header
                    userHeaderSection
                    
                    // Stats section
                    userStatsSection
                    
                    // Projects section
                    userProjectsSection
                    
                    // Recent activity
                    recentActivitySection
                }
                .padding()
            }
            .navigationTitle(user.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Edit Role") {
                            // Edit role action
                        }
                        
                        Divider()
                        
                        Button("Remove from Team", role: .destructive) {
                            showingDeleteAlert = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.taskOrbitOrange)
                    }
                }
            }
        }
        .alert("Remove User", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                teamViewModel.removeUser(user)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to remove \(user.displayName) from the team?")
        }
    }
    
    private var userHeaderSection: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.taskOrbitOrange)
                .frame(width: 80, height: 80)
                .overlay(
                    Text(user.initials)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(user.displayName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primaryText)
                
                Text(user.email)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondaryText)
                
                HStack(spacing: 8) {
                    Text(user.role.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.taskOrbitOrange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.taskOrbitOrange.opacity(0.1))
                        .cornerRadius(8)
                    
                    Circle()
                        .fill(user.isActive ? Color.profitGreen : Color.neutralGray)
                        .frame(width: 8, height: 8)
                    
                    Text(user.isActive ? "Active" : "Inactive")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondaryText)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.taskOrbitSecondaryBackground)
        .cornerRadius(16)
    }
    
    private var userStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primaryText)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatCard(
                    title: "Tasks Completed",
                    value: "\(user.tasksCompleted)",
                    color: .profitGreen
                )
                
                StatCard(
                    title: "Coins Earned",
                    value: "\(user.coinsEarned)",
                    color: .taskOrbitOrange
                )
                
                StatCard(
                    title: "Projects Owned",
                    value: "\(user.projectsOwned)",
                    color: .blue
                )
                
                StatCard(
                    title: "Productivity Score",
                    value: "\(Int(user.productivityScore))",
                    color: .purple
                )
            }
        }
    }
    
    private var userProjectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Projects")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primaryText)
            
            if userProjects.isEmpty {
                Text("No projects assigned")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondaryText)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.taskOrbitSecondaryBackground)
                    .cornerRadius(8)
            } else {
                VStack(spacing: 8) {
                    ForEach(userProjects.prefix(3)) { project in
                        HStack {
                            Circle()
                                .fill(Color(hex: project.color))
                                .frame(width: 12, height: 12)
                            
                            Text(project.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primaryText)
                            
                            Spacer()
                            
                            Text(project.status.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondaryText)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.taskOrbitSecondaryBackground)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private var userProjects: [Project] {
        teamViewModel.projects.filter { project in
            project.ownerId == user.id || project.memberIds.contains(user.id)
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primaryText)
            
            VStack(spacing: 8) {
                ActivityRowView(
                    icon: "checkmark.circle.fill",
                    title: "Completed task",
                    subtitle: "Design App Logo",
                    time: "2 hours ago",
                    color: .profitGreen
                )
                
                ActivityRowView(
                    icon: "plus.circle.fill",
                    title: "Created project",
                    subtitle: "Marketing Campaign",
                    time: "1 day ago",
                    color: .blue
                )
                
                ActivityRowView(
                    icon: "star.fill",
                    title: "Earned 25 coins",
                    subtitle: "Task completion bonus",
                    time: "2 days ago",
                    color: .taskOrbitOrange
                )
            }
        }
    }
}

struct ActivityRowView: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primaryText)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            Text(time)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondaryText)
        }
        .padding()
        .background(Color.taskOrbitSecondaryBackground)
        .cornerRadius(8)
    }
}


#Preview {
    InviteUserView()
        .environmentObject(TeamViewModel())
}
