//
//  ContentView.swift
//  TaskOrbit Ano
//
//  Created by Assistant on 9/6/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var dataService: DataService
    @EnvironmentObject private var analyticsService: AnalyticsService
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject private var teamViewModel = TeamViewModel()
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab = 0
    @State private var showingAddTask = false
    @State private var showingAddProject = false
    @State private var coinsAnimationTrigger = false
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else {
                mainAppView
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .coinsAwarded)) { notification in
            // Trigger coins animation
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                coinsAnimationTrigger.toggle()
            }
        }
    }
    
    private var mainAppView: some View {
        TabView(selection: $selectedTab) {
            // Tasks Tab
            NavigationView {
                TasksView()
                    .environmentObject(taskViewModel)
            }
            .tabItem {
                Image(systemName: selectedTab == 0 ? "list.bullet.circle.fill" : "list.bullet.circle")
                Text("Tasks")
            }
            .tag(0)
            
            // Projects Tab
            NavigationView {
                ProjectsView()
                    .environmentObject(teamViewModel)
            }
            .tabItem {
                Image(systemName: selectedTab == 1 ? "folder.fill" : "folder")
                Text("Projects")
            }
            .tag(1)
            
            // Analytics Tab
            ProjectAnalyticsView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "chart.bar.fill" : "chart.bar")
                    Text("Analytics")
                }
                .tag(2)
            
            // Team Tab
            NavigationView {
                TeamView()
                    .environmentObject(teamViewModel)
            }
            .tabItem {
                Image(systemName: selectedTab == 3 ? "person.3.fill" : "person.3")
                Text("Team")
            }
            .tag(3)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "gear.circle.fill" : "gear.circle")
                    Text("Settings")
                }
                .tag(4)
        }
        .tint(.taskOrbitOrange)
        .overlay(
            // Floating Action Button
        VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    Menu {
                        Button(action: { showingAddTask = true }) {
                            Label("Add Task", systemImage: "plus.circle")
                        }
                        
                        Button(action: { showingAddProject = true }) {
                            Label("Add Project", systemImage: "folder.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(Color.taskOrbitGradient)
                                    .shadow(color: .taskOrbitOrange.opacity(0.3), radius: 10, x: 0, y: 5)
                            )
                    }
                    .scaleEffect(coinsAnimationTrigger ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: coinsAnimationTrigger)
                    .padding(.trailing, 20)
                    .padding(.bottom, 90)
                }
            }
        )
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
                .environmentObject(taskViewModel)
        }
        .sheet(isPresented: $showingAddProject) {
            AddProjectView()
                .environmentObject(teamViewModel)
        }
    }
}

// MARK: - Tasks View
struct TasksView: View {
    @EnvironmentObject private var taskViewModel: TaskViewModel
    @EnvironmentObject private var dataService: DataService
    @State private var showingFilters = false
    @State private var selectedTask: Task?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with search and filters
            headerView
            
            // Tasks list
            if taskViewModel.isLoading {
                Spacer()
                ProgressView("Loading tasks...")
                    .foregroundColor(.taskOrbitOrange)
                Spacer()
            } else if taskViewModel.filteredTasks.isEmpty {
                emptyStateView
            } else {
                tasksListView
            }
        }
        .navigationTitle("Tasks")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingFilters = true }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(.taskOrbitOrange)
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            TaskFiltersView()
                .environmentObject(taskViewModel)
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: Binding(
                get: { task },
                set: { updatedTask in
                    taskViewModel.updateTask(updatedTask)
                }
            ))
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondaryText)
                
                TextField("Search tasks...", text: $taskViewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !taskViewModel.searchText.isEmpty {
                    Button(action: { taskViewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondaryText)
                    }
                }
            }
            .padding()
            .background(Color.taskOrbitSecondaryBackground)
            .cornerRadius(12)
            
            // Quick stats
            HStack(spacing: 16) {
                StatCard(
                    title: "Pending",
                    value: "\(taskViewModel.pendingTasksCount)",
                    color: .taskOrbitOrange
                )
                
                StatCard(
                    title: "Completed",
                    value: "\(taskViewModel.completedTasksCount)",
                    color: .profitGreen
                )
                
                StatCard(
                    title: "Overdue",
                    value: "\(taskViewModel.overdueTasks.count)",
                    color: .lossRed
                )
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 60))
                .foregroundColor(.taskOrbitOrange.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Tasks Found")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primaryText)
                
                Text("Create your first task to get started with TaskOrbit Ano")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var tasksListView: some View {
        List {
            ForEach(taskViewModel.filteredTasks) { task in
                TaskRowView(task: task) {
                    selectedTask = task
                }
                .listRowBackground(Color.taskOrbitBackground)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            taskViewModel.refreshTasks()
        }
    }
}

// MARK: - Projects View
struct ProjectsView: View {
    @EnvironmentObject private var teamViewModel: TeamViewModel
    @State private var showingProjectDetail: Project?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Projects list
            if teamViewModel.isLoading {
                Spacer()
                ProgressView("Loading projects...")
                    .foregroundColor(.taskOrbitOrange)
                Spacer()
            } else if teamViewModel.filteredProjects.isEmpty {
                emptyProjectsView
            } else {
                projectsListView
            }
        }
        .navigationTitle("Projects")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $showingProjectDetail) { project in
            ProjectDetailView(project: project)
                .environmentObject(teamViewModel)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondaryText)
                
                TextField("Search projects...", text: $teamViewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !teamViewModel.searchText.isEmpty {
                    Button(action: { teamViewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondaryText)
                    }
                }
            }
            .padding()
            .background(Color.taskOrbitSecondaryBackground)
            .cornerRadius(12)
            
            // Quick stats
            HStack(spacing: 16) {
                StatCard(
                    title: "Active",
                    value: "\(teamViewModel.activeProjects.count)",
                    color: .profitGreen
                )
                
                StatCard(
                    title: "Completed",
                    value: "\(teamViewModel.completedProjects.count)",
                    color: .blue
                )
                
                StatCard(
                    title: "Budget",
                    value: formatCurrency(teamViewModel.totalProjectBudget),
                    color: .taskOrbitOrange
                )
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private var emptyProjectsView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.taskOrbitOrange.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Projects Found")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primaryText)
                
                Text("Create your first project to organize your tasks")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var projectsListView: some View {
        List {
            ForEach(teamViewModel.filteredProjects) { project in
                ProjectRowView(project: project) {
                    showingProjectDetail = project
                }
                .listRowBackground(Color.taskOrbitBackground)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            teamViewModel.refreshData()
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Team View
struct TeamView: View {
    @EnvironmentObject private var teamViewModel: TeamViewModel
    @EnvironmentObject private var dataService: DataService
    @State private var showingInviteSheet = false
    @State private var selectedUser: User?
    @State private var showingUserDetail = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with stats
            headerView
            
            // Team list
            if teamViewModel.users.isEmpty {
                emptyTeamView
            } else {
                teamListView
            }
        }
        .navigationTitle("Team")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingInviteSheet = true }) {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.taskOrbitOrange)
                }
            }
        }
        .sheet(isPresented: $showingInviteSheet) {
            InviteUserView()
                .environmentObject(teamViewModel)
        }
        .sheet(item: $selectedUser) { user in
            UserDetailView(user: user)
                .environmentObject(teamViewModel)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondaryText)
                
                TextField("Search team members...", text: $teamViewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !teamViewModel.searchText.isEmpty {
                    Button(action: { teamViewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondaryText)
                    }
                }
            }
            .padding()
            .background(Color.taskOrbitSecondaryBackground)
            .cornerRadius(12)
            
            // Team stats
            HStack(spacing: 16) {
                StatCard(
                    title: "Total Members",
                    value: "\(teamViewModel.users.count)",
                    color: .taskOrbitOrange
                )
                
                StatCard(
                    title: "Active Projects",
                    value: "\(teamViewModel.activeProjects.count)",
                    color: .profitGreen
                )
                
                StatCard(
                    title: "My Projects",
                    value: "\(teamViewModel.myProjects.count)",
                    color: .blue
                )
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private var emptyTeamView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "person.3.sequence")
                .font(.system(size: 60))
                .foregroundColor(.taskOrbitOrange.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Team Members")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primaryText)
                
                Text("Invite team members to collaborate on projects")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingInviteSheet = true }) {
                Text("Invite Team Member")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.taskOrbitGradient)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
    
    private var teamListView: some View {
        List {
            ForEach(teamViewModel.filteredUsers) { user in
                TeamMemberRowView(user: user) {
                    selectedUser = user
                }
                .listRowBackground(Color.taskOrbitBackground)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            teamViewModel.refreshData()
        }
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.taskOrbitSecondaryBackground)
        .cornerRadius(12)
    }
}

struct TaskRowView: View {
    let task: Task
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Completion indicator
                Button(action: {
                    // Toggle completion
                }) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(task.isCompleted ? .profitGreen : .gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryText)
                        .strikethrough(task.isCompleted)
                    
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondaryText)
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: 8) {
                        // Priority indicator
                        HStack(spacing: 4) {
                            Circle()
                                .fill(priorityColor(task.priority))
                                .frame(width: 6, height: 6)
                            
                            Text(task.priority.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondaryText)
                        }
                        
                        // Due date
                        if let dueDate = task.dueDate {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 10))
                                
                                Text(dueDate, style: .date)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(isOverdue(dueDate) ? .lossRed : .secondaryText)
                        }
                        
                        // Budget indicator
                        if let budget = task.budget {
                            HStack(spacing: 4) {
                                Image(systemName: "dollarsign.circle")
                                    .font(.system(size: 10))
                                
                                Text(formatCurrency(budget))
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(task.isOverBudget ? .lossRed : .secondaryText)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondaryText)
            }
            .padding()
            .background(Color.taskOrbitSecondaryBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func priorityColor(_ priority: Task.TaskPriority) -> Color {
        switch priority {
        case .low: return .priorityLow
        case .medium: return .priorityMedium
        case .high: return .priorityHigh
        case .urgent: return .priorityUrgent
        }
    }
    
    private func isOverdue(_ dueDate: Date) -> Bool {
        !task.isCompleted && dueDate < Date()
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

struct ProjectRowView: View {
    let project: Project
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(project.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                    
                    Text(project.status.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor(project.status))
                        .cornerRadius(12)
                }
                
                if !project.description.isEmpty {
                    Text(project.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondaryText)
                        .lineLimit(2)
                }
                
                HStack {
                    if let budget = project.budget {
                        Text("Budget: \(formatCurrency(budget))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondaryText)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("\(Int(project.progress * 100))%")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.taskOrbitOrange)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.secondaryText)
                    }
                }
            }
            .padding()
            .background(Color.taskOrbitSecondaryBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func statusColor(_ status: Project.ProjectStatus) -> Color {
        switch status {
        case .planning: return .statusPlanning
        case .active: return .statusActive
        case .onHold: return .statusOnHold
        case .completed: return .statusCompleted
        case .cancelled: return .statusCancelled
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Placeholder Views
struct TaskFiltersView: View {
    @EnvironmentObject private var taskViewModel: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Priority") {
                    Picker("Priority", selection: $taskViewModel.selectedPriority) {
                        Text("All").tag(Task.TaskPriority?.none)
                        ForEach(Task.TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(Task.TaskPriority?.some(priority))
                        }
                    }
                }
                
                Section("Options") {
                    Toggle("Show Completed Tasks", isOn: $taskViewModel.showCompletedTasks)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        taskViewModel.clearFilters()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AddTaskView: View {
    @EnvironmentObject private var taskViewModel: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Task Title", text: $title)
                    TextField("Description", text: $description)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        taskViewModel.addTask(title: title, description: description)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

struct AddProjectView: View {
    @EnvironmentObject private var teamViewModel: TeamViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Project Details") {
                    TextField("Project Name", text: $name)
                    TextField("Description", text: $description)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Add Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        teamViewModel.createProject(name: name, description: description, budget: nil, endDate: nil)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct ProjectDetailView: View {
    let project: Project
    @EnvironmentObject private var teamViewModel: TeamViewModel
    @EnvironmentObject private var dataService: DataService
    @StateObject private var taskViewModel = TaskViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var showingAddTaskSheet = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Project header
                projectHeaderSection
                
                // Tab selector
                tabSelector
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    overviewTab.tag(0)
                    tasksTab.tag(1)
                    teamTab.tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle(project.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Edit Project") {
                            showingEditSheet = true
                        }
                        
                        Button("Add Task") {
                            showingAddTaskSheet = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.taskOrbitOrange)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditProjectSheet(project: project)
        }
        .sheet(isPresented: $showingAddTaskSheet) {
            AddTaskSheet(projectId: project.id)
        }
    }
    
    private var projectHeaderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Circle()
                    .fill(Color(hex: project.color))
                    .frame(width: 16, height: 16)
                
                Text(project.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Text(project.status.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(statusColor(project.status))
                    .cornerRadius(12)
            }
            
            if !project.description.isEmpty {
                Text(project.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondaryText)
                    .lineLimit(2)
            }
            
            // Progress and stats
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Progress")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondaryText)
                    Text("\(Int(project.progress * 100))%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.taskOrbitOrange)
                }
                
                if let budget = project.budget {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Budget")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondaryText)
                        Text(formatCurrency(budget))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primaryText)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Team")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondaryText)
                    Text("\(project.memberIds.count + 1)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primaryText)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.taskOrbitSecondaryBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(Array(["Overview", "Tasks", "Team"].enumerated()), id: \.offset) { index, title in
                Button(action: { selectedTab = index }) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selectedTab == index ? .taskOrbitOrange : .secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Rectangle()
                                .fill(selectedTab == index ? Color.taskOrbitOrange.opacity(0.1) : Color.clear)
                        )
                        .overlay(
                            Rectangle()
                                .fill(selectedTab == index ? Color.taskOrbitOrange : Color.clear)
                                .frame(height: 2)
                                .offset(y: 12)
                        )
                }
            }
        }
        .background(Color.taskOrbitBackground)
        .padding(.horizontal)
    }
    
    private var overviewTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                let projectTasks = dataService.getTasksForProject(project.id)
                let completedTasks = projectTasks.filter { $0.isCompleted }
                
                // Key metrics
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    StatCard(title: "Total Tasks", value: "\(projectTasks.count)", color: .blue)
                    StatCard(title: "Completed", value: "\(completedTasks.count)", color: .profitGreen)
                    StatCard(title: "Team Members", value: "\(project.memberIds.count + 1)", color: .taskOrbitOrange)
                    StatCard(title: "Budget Used", value: "\(Int(project.budgetUtilization))%", color: .purple)
                }
                
                // Recent activity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Activity")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    VStack(spacing: 8) {
                        ActivityRow(icon: "checkmark.circle.fill", title: "Task completed", subtitle: "Design App Logo", time: "2 hours ago", color: .profitGreen)
                        ActivityRow(icon: "plus.circle.fill", title: "New task added", subtitle: "Implement Authentication", time: "1 day ago", color: .taskOrbitOrange)
                        ActivityRow(icon: "person.badge.plus", title: "Member joined", subtitle: "Sarah Chen", time: "2 days ago", color: .blue)
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
    
    private var tasksTab: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                let projectTasks = dataService.getTasksForProject(project.id)
                
                if projectTasks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 40))
                            .foregroundColor(.taskOrbitOrange.opacity(0.5))
                        
                        Text("No tasks yet")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primaryText)
                        
                        Button("Add First Task") {
                            showingAddTaskSheet = true
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.taskOrbitOrange)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(projectTasks) { task in
                        TaskRowView(task: task) {
                            // Handle task tap
                        }
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
    
    private var teamTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Project owner
                VStack(alignment: .leading, spacing: 12) {
                    Text("Project Owner")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    if let owner = teamViewModel.getUserById(project.ownerId) {
                        TeamMemberRow(user: owner)
                    }
                }
                
                // Team members
                VStack(alignment: .leading, spacing: 12) {
                    Text("Team Members (\(project.memberIds.count))")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    if project.memberIds.isEmpty {
                        Text("No team members assigned")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondaryText)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.taskOrbitSecondaryBackground)
                            .cornerRadius(8)
                    } else {
                        ForEach(project.memberIds, id: \.self) { memberId in
                            if let member = teamViewModel.getUserById(memberId) {
                                TeamMemberRow(user: member)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
    
    private func statusColor(_ status: Project.ProjectStatus) -> Color {
        switch status {
        case .planning: return .statusPlanning
        case .active: return .statusActive
        case .onHold: return .statusOnHold
        case .completed: return .statusCompleted
        case .cancelled: return .statusCancelled
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Additional Supporting Views
struct TeamMemberRowView: View {
    let user: User
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.taskOrbitOrange)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(user.initials)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    Text(user.role.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondaryText)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 10))
                                .foregroundColor(.profitGreen)
                            Text("\(user.tasksCompleted)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondaryText)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.taskOrbitOrange)
                            Text("\(user.coinsEarned)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondaryText)
                        }
                    }
                }
                
                Spacer()
                
                Circle()
                    .fill(user.isActive ? Color.profitGreen : Color.neutralGray)
                    .frame(width: 8, height: 8)
            }
            .padding()
            .background(Color.taskOrbitSecondaryBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TeamMemberRow: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.taskOrbitOrange)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(user.initials)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Text(user.role.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            Circle()
                .fill(user.isActive ? Color.profitGreen : Color.neutralGray)
                .frame(width: 6, height: 6)
        }
        .padding()
        .background(Color.taskOrbitSecondaryBackground)
        .cornerRadius(8)
    }
}

struct ActivityRow: View {
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

struct EditProjectSheet: View {
    let project: Project
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var description: String
    
    init(project: Project) {
        self.project = project
        _name = State(initialValue: project.name)
        _description = State(initialValue: project.description)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Project Information") {
                    TextField("Project Name", text: $name)
                    TextField("Description", text: $description)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        // Save project changes
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
}

struct AddTaskSheet: View {
    let projectId: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Information") {
                    TextField("Task Title", text: $title)
                    TextField("Description", text: $description)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        // Add task to project
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                    .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataService.shared)
        .environmentObject(AnalyticsService.shared)
}
