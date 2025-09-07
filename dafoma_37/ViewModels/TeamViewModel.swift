//
//  TeamViewModel.swift
//  TaskOrbit Ano
//
//  Created by Assistant on 9/6/25.
//

import Foundation
import Combine

class TeamViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var users: [User] = []
    @Published var currentUser: User = User.currentUser
    @Published var selectedProject: Project?
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showInviteSheet: Bool = false
    @Published var inviteEmail: String = ""
    
    private let dataService = DataService.shared
    private let analyticsService = AnalyticsService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        loadData()
    }
    
    private func setupBindings() {
        // Subscribe to data service updates
        dataService.$projects
            .assign(to: \.projects, on: self)
            .store(in: &cancellables)
        
        dataService.$users
            .assign(to: \.users, on: self)
            .store(in: &cancellables)
        
        dataService.$currentUser
            .assign(to: \.currentUser, on: self)
            .store(in: &cancellables)
    }
    
    private func loadData() {
        isLoading = true
        
        // Simulate loading delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
        }
    }
    
    // MARK: - Project Operations
    func createProject(name: String, description: String, budget: Double?, endDate: Date?) {
        let newProject = Project(
            name: name,
            description: description,
            budget: budget,
            endDate: endDate,
            ownerId: currentUser.id
        )
        
        dataService.addProject(newProject)
    }
    
    func updateProject(_ project: Project) {
        dataService.updateProject(project)
    }
    
    func deleteProject(_ project: Project) {
        guard canManageProject(project) else {
            errorMessage = "You don't have permission to delete this project"
            return
        }
        
        dataService.deleteProject(project)
    }
    
    func addMemberToProject(_ project: Project, userId: UUID) {
        guard canManageProject(project) else {
            errorMessage = "You don't have permission to manage this project"
            return
        }
        
        var updatedProject = project
        if !updatedProject.memberIds.contains(userId) {
            updatedProject.memberIds.append(userId)
            updateProject(updatedProject)
        }
    }
    
    func removeMemberFromProject(_ project: Project, userId: UUID) {
        guard canManageProject(project) else {
            errorMessage = "You don't have permission to manage this project"
            return
        }
        
        var updatedProject = project
        updatedProject.memberIds.removeAll { $0 == userId }
        updateProject(updatedProject)
    }
    
    // MARK: - User Operations
    func inviteUser(email: String, to project: Project, role: User.UserRole = .member) {
        guard canManageProject(project) else {
            errorMessage = "You don't have permission to invite users to this project"
            return
        }
        
        // Check if user already exists
        if let existingUser = users.first(where: { $0.email == email }) {
            addMemberToProject(project, userId: existingUser.id)
            return
        }
        
        // Create new user (in a real app, this would send an invitation)
        let newUser = User(
            name: email.components(separatedBy: "@").first?.capitalized ?? "New User",
            email: email,
            role: role
        )
        
        dataService.addUser(newUser)
        addMemberToProject(project, userId: newUser.id)
        
        inviteEmail = ""
        showInviteSheet = false
    }
    
    func updateUserRole(_ user: User, role: User.UserRole) {
        guard currentUser.role == .admin else {
            errorMessage = "Only administrators can change user roles"
            return
        }
        
        var updatedUser = user
        updatedUser.role = role
        dataService.updateUser(updatedUser)
    }
    
    func addUser(_ user: User) {
        dataService.addUser(user)
    }
    
    func removeUser(_ user: User) {
        guard currentUser.role == .admin else {
            errorMessage = "Only administrators can remove users"
            return
        }
        
        dataService.deleteUser(user)
    }
    
    // MARK: - Permission Checks
    func canManageProject(_ project: Project) -> Bool {
        return project.ownerId == currentUser.id || 
               currentUser.role == .admin ||
               (currentUser.role == .projectManager && project.memberIds.contains(currentUser.id))
    }
    
    func canEditProject(_ project: Project) -> Bool {
        return canManageProject(project)
    }
    
    func canViewProject(_ project: Project) -> Bool {
        return project.ownerId == currentUser.id ||
               project.memberIds.contains(currentUser.id) ||
               currentUser.role == .admin
    }
    
    func canInviteUsers(_ project: Project) -> Bool {
        return canManageProject(project)
    }
    
    func canAssignTasks(_ project: Project) -> Bool {
        return currentUser.role.permissions.contains(.assignTasks) && canManageProject(project)
    }
    
    // MARK: - Computed Properties
    var myProjects: [Project] {
        projects.filter { $0.ownerId == currentUser.id }
    }
    
    var sharedProjects: [Project] {
        projects.filter { project in
            project.ownerId != currentUser.id && project.memberIds.contains(currentUser.id)
        }
    }
    
    var activeProjects: [Project] {
        projects.filter { $0.status == .active }
    }
    
    var completedProjects: [Project] {
        projects.filter { $0.status == .completed }
    }
    
    var totalProjectBudget: Double {
        projects.compactMap { $0.budget }.reduce(0, +)
    }
    
    var totalProjectCost: Double {
        projects.map { $0.actualCost }.reduce(0, +)
    }
    
    var teamMembers: [User] {
        guard let selectedProject = selectedProject else { return [] }
        
        let memberIds = [selectedProject.ownerId] + selectedProject.memberIds
        return users.filter { memberIds.contains($0.id) }
    }
    
    var availableUsers: [User] {
        guard let selectedProject = selectedProject else { return users }
        
        let memberIds = [selectedProject.ownerId] + selectedProject.memberIds
        return users.filter { !memberIds.contains($0.id) }
    }
    
    // MARK: - Team Analytics
    func getTeamProductivity(for project: Project) -> TeamProductivity {
        let tasks = dataService.getTasksForProject(project.id)
        let completedTasks = tasks.filter { $0.isCompleted }
        let memberIds = [project.ownerId] + project.memberIds
        
        var memberProductivity: [UserProductivitySummary] = []
        
        for memberId in memberIds {
            guard let user = users.first(where: { $0.id == memberId }) else { continue }
            
            let userTasks = tasks.filter { $0.assignedUserId == memberId }
            let userCompletedTasks = userTasks.filter { $0.isCompleted }
            
            let summary = UserProductivitySummary(
                user: user,
                totalTasks: userTasks.count,
                completedTasks: userCompletedTasks.count,
                completionRate: userTasks.isEmpty ? 0 : Double(userCompletedTasks.count) / Double(userTasks.count) * 100,
                averageTaskCost: userTasks.isEmpty ? 0 : userTasks.map { $0.actualCost }.reduce(0, +) / Double(userTasks.count)
            )
            
            memberProductivity.append(summary)
        }
        
        return TeamProductivity(
            projectId: project.id,
            projectName: project.name,
            totalMembers: memberIds.count,
            totalTasks: tasks.count,
            completedTasks: completedTasks.count,
            overallProgress: tasks.isEmpty ? 0 : Double(completedTasks.count) / Double(tasks.count) * 100,
            memberProductivity: memberProductivity
        )
    }
    
    func getProjectAnalytics(for project: Project) -> ProjectAnalytics? {
        return analyticsService.projectAnalytics.first { $0.projectId == project.id }
    }
    
    // MARK: - Search and Filter
    var filteredProjects: [Project] {
        if searchText.isEmpty {
            return projects
        }
        
        return projects.filter { project in
            project.name.localizedCaseInsensitiveContains(searchText) ||
            project.description.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return users
        }
        
        return users.filter { user in
            user.name.localizedCaseInsensitiveContains(searchText) ||
            user.email.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - Utility Methods
    func refreshData() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
        }
    }
    
    func getUserById(_ id: UUID) -> User? {
        return users.first { $0.id == id }
    }
    
    func getProjectById(_ id: UUID) -> Project? {
        return projects.first { $0.id == id }
    }
    
    func isProjectMember(_ project: Project, userId: UUID) -> Bool {
        return project.ownerId == userId || project.memberIds.contains(userId)
    }
    
    func clearSearch() {
        searchText = ""
    }
}

// MARK: - Team Analytics Data Structures
struct TeamProductivity {
    let projectId: UUID
    let projectName: String
    let totalMembers: Int
    let totalTasks: Int
    let completedTasks: Int
    let overallProgress: Double
    let memberProductivity: [UserProductivitySummary]
}

struct UserProductivitySummary: Identifiable {
    let id = UUID()
    let user: User
    let totalTasks: Int
    let completedTasks: Int
    let completionRate: Double
    let averageTaskCost: Double
}
