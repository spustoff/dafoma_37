//
//  DataService.swift
//  TaskOrbit Ano
//
//  Created by Assistant on 9/6/25.
//

import Foundation
import Combine

class DataService: ObservableObject {
    static let shared = DataService()
    
    @Published var tasks: [Task] = []
    @Published var projects: [Project] = []
    @Published var users: [User] = []
    @Published var currentUser: User = User.currentUser
    
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Keys for UserDefaults
    private enum Keys {
        static let tasks = "TaskOrbitTasks"
        static let projects = "TaskOrbitProjects"
        static let users = "TaskOrbitUsers"
        static let currentUser = "TaskOrbitCurrentUser"
        static let hasCompletedOnboarding = "TaskOrbitOnboardingCompleted"
    }
    
    private init() {
        loadData()
    }
    
    // MARK: - Data Loading
    private func loadData() {
        loadTasks()
        loadProjects()
        loadUsers()
        loadCurrentUser()
    }
    
    private func loadTasks() {
        if let data = userDefaults.data(forKey: Keys.tasks),
           let decodedTasks = try? JSONDecoder().decode([Task].self, from: data) {
            self.tasks = decodedTasks
        } else {
            self.tasks = Task.sampleTasks
            saveTasks()
        }
    }
    
    private func loadProjects() {
        if let data = userDefaults.data(forKey: Keys.projects),
           let decodedProjects = try? JSONDecoder().decode([Project].self, from: data) {
            self.projects = decodedProjects
        } else {
            self.projects = Project.sampleProjects
            saveProjects()
        }
    }
    
    private func loadUsers() {
        if let data = userDefaults.data(forKey: Keys.users),
           let decodedUsers = try? JSONDecoder().decode([User].self, from: data) {
            self.users = decodedUsers
        } else {
            self.users = User.sampleUsers
            saveUsers()
        }
    }
    
    private func loadCurrentUser() {
        if let data = userDefaults.data(forKey: Keys.currentUser),
           let decodedUser = try? JSONDecoder().decode(User.self, from: data) {
            self.currentUser = decodedUser
        } else {
            self.currentUser = User.currentUser
            saveCurrentUser()
        }
    }
    
    // MARK: - Data Saving
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            userDefaults.set(encoded, forKey: Keys.tasks)
        }
    }
    
    private func saveProjects() {
        if let encoded = try? JSONEncoder().encode(projects) {
            userDefaults.set(encoded, forKey: Keys.projects)
        }
    }
    
    private func saveUsers() {
        if let encoded = try? JSONEncoder().encode(users) {
            userDefaults.set(encoded, forKey: Keys.users)
        }
    }
    
    private func saveCurrentUser() {
        if let encoded = try? JSONEncoder().encode(currentUser) {
            userDefaults.set(encoded, forKey: Keys.currentUser)
        }
    }
    
    // MARK: - Task Operations
    func addTask(_ task: Task) {
        tasks.append(task)
        saveTasks()
        
        // Award coins for creating a task
        awardCoins(10, for: "Task Created")
    }
    
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            let wasCompleted = tasks[index].isCompleted
            tasks[index] = task
            
            // Award coins for completing a task
            if !wasCompleted && task.isCompleted {
                awardCoins(25, for: "Task Completed")
                currentUser.tasksCompleted += 1
                saveCurrentUser()
            }
            
            saveTasks()
        }
    }
    
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    func getTasksForProject(_ projectId: UUID) -> [Task] {
        return tasks.filter { $0.projectId == projectId }
    }
    
    func getTasksForUser(_ userId: UUID) -> [Task] {
        return tasks.filter { $0.assignedUserId == userId }
    }
    
    // MARK: - Project Operations
    func addProject(_ project: Project) {
        projects.append(project)
        saveProjects()
        
        if project.ownerId == currentUser.id {
            currentUser.projectsOwned += 1
            saveCurrentUser()
            awardCoins(50, for: "Project Created")
        }
    }
    
    func updateProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
            saveProjects()
        }
    }
    
    func deleteProject(_ project: Project) {
        // Delete associated tasks
        tasks.removeAll { $0.projectId == project.id }
        saveTasks()
        
        // Delete project
        projects.removeAll { $0.id == project.id }
        saveProjects()
        
        if project.ownerId == currentUser.id {
            currentUser.projectsOwned = max(0, currentUser.projectsOwned - 1)
            saveCurrentUser()
        }
    }
    
    func getProjectsForUser(_ userId: UUID) -> [Project] {
        return projects.filter { project in
            project.ownerId == userId || project.memberIds.contains(userId)
        }
    }
    
    // MARK: - User Operations
    func updateCurrentUser(_ user: User) {
        currentUser = user
        saveCurrentUser()
    }
    
    func addUser(_ user: User) {
        users.append(user)
        saveUsers()
    }
    
    func updateUser(_ user: User) {
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = user
            saveUsers()
        }
    }
    
    func deleteUser(_ user: User) {
        users.removeAll { $0.id == user.id }
        saveUsers()
        
        // Remove user from projects
        for i in 0..<projects.count {
            projects[i].memberIds.removeAll { $0 == user.id }
        }
        saveProjects()
        
        // Unassign tasks
        for i in 0..<tasks.count {
            if tasks[i].assignedUserId == user.id {
                tasks[i].assignedUserId = nil
            }
        }
        saveTasks()
    }
    
    // MARK: - Gamification
    private func awardCoins(_ amount: Int, for reason: String) {
        currentUser.coinsEarned += amount
        saveCurrentUser()
        
        // Post notification for UI feedback
        NotificationCenter.default.post(
            name: .coinsAwarded,
            object: nil,
            userInfo: ["amount": amount, "reason": reason]
        )
    }
    
    // MARK: - Comments
    func addComment(to taskId: UUID, comment: TaskComment) {
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            tasks[index].comments.append(comment)
            saveTasks()
            awardCoins(5, for: "Comment Added")
        }
    }
    
    // MARK: - Onboarding
    var hasCompletedOnboarding: Bool {
        get {
            userDefaults.bool(forKey: Keys.hasCompletedOnboarding)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.hasCompletedOnboarding)
        }
    }
    
    // MARK: - Data Reset (for settings)
    func resetAllData() {
        userDefaults.removeObject(forKey: Keys.tasks)
        userDefaults.removeObject(forKey: Keys.projects)
        userDefaults.removeObject(forKey: Keys.users)
        userDefaults.removeObject(forKey: Keys.currentUser)
        userDefaults.removeObject(forKey: Keys.hasCompletedOnboarding)
        
        loadData()
    }
    
    // MARK: - Export/Import Data
    func exportData() -> Data? {
        let exportData = ExportData(
            tasks: tasks,
            projects: projects,
            users: users,
            currentUser: currentUser
        )
        
        return try? JSONEncoder().encode(exportData)
    }
    
    func importData(_ data: Data) -> Bool {
        guard let importData = try? JSONDecoder().decode(ExportData.self, from: data) else {
            return false
        }
        
        self.tasks = importData.tasks
        self.projects = importData.projects
        self.users = importData.users
        self.currentUser = importData.currentUser
        
        saveTasks()
        saveProjects()
        saveUsers()
        saveCurrentUser()
        
        return true
    }
}

// MARK: - Export Data Structure
private struct ExportData: Codable {
    let tasks: [Task]
    let projects: [Project]
    let users: [User]
    let currentUser: User
}

// MARK: - Notification Names
extension Notification.Name {
    static let coinsAwarded = Notification.Name("CoinsAwarded")
}
