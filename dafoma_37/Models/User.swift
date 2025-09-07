//
//  User.swift
//  TaskOrbit Ano
//
//  Created by Assistant on 9/6/25.
//

import Foundation

struct User: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var email: String
    var profileImageURL: String?
    var role: UserRole = .member
    var coinsEarned: Int = 0
    var tasksCompleted: Int = 0
    var projectsOwned: Int = 0
    var joinedAt: Date = Date()
    var isActive: Bool = true
    var preferences: UserPreferences = UserPreferences()
    
    enum UserRole: String, CaseIterable, Codable {
        case admin = "Admin"
        case projectManager = "Project Manager"
        case member = "Member"
        case viewer = "Viewer"
        
        var permissions: [Permission] {
            switch self {
            case .admin:
                return Permission.allCases
            case .projectManager:
                return [.createProject, .editProject, .assignTasks, .viewAnalytics, .manageTeam]
            case .member:
                return [.createTask, .editOwnTasks, .comment, .viewProjects]
            case .viewer:
                return [.viewProjects, .comment]
            }
        }
    }
    
    enum Permission: String, CaseIterable, Codable {
        case createProject = "Create Project"
        case editProject = "Edit Project"
        case deleteProject = "Delete Project"
        case createTask = "Create Task"
        case editOwnTasks = "Edit Own Tasks"
        case editAllTasks = "Edit All Tasks"
        case assignTasks = "Assign Tasks"
        case viewAnalytics = "View Analytics"
        case manageTeam = "Manage Team"
        case comment = "Comment"
        case viewProjects = "View Projects"
    }
    
    var displayName: String {
        name.isEmpty ? email : name
    }
    
    var initials: String {
        let components = name.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.map { String($0) }
        return initials.prefix(2).joined().uppercased()
    }
    
    var productivityScore: Double {
        let baseScore = Double(tasksCompleted * 10 + coinsEarned)
        let projectMultiplier = Double(projectsOwned) * 50
        return baseScore + projectMultiplier
    }
}

struct UserPreferences: Codable, Hashable {
    var enableNotifications: Bool = true
    var enableDarkMode: Bool = false
    var defaultProjectView: ProjectView = .list
    var autoAssignTasks: Bool = false
    var showBudgetWarnings: Bool = true
    var preferredCurrency: String = "USD"
    var workingHoursStart: Int = 9 // 9 AM
    var workingHoursEnd: Int = 17 // 5 PM
    
    enum ProjectView: String, CaseIterable, Codable {
        case list = "List"
        case grid = "Grid"
        case kanban = "Kanban"
    }
}

extension User {
    static let sampleUsers: [User] = [
        User(
            name: "Alex Johnson",
            email: "alex.johnson@example.com",
            role: .admin,
            coinsEarned: 1250,
            tasksCompleted: 45,
            projectsOwned: 3
        ),
        User(
            name: "Sarah Chen",
            email: "sarah.chen@example.com",
            role: .projectManager,
            coinsEarned: 890,
            tasksCompleted: 32,
            projectsOwned: 2
        ),
        User(
            name: "Mike Rodriguez",
            email: "mike.rodriguez@example.com",
            role: .member,
            coinsEarned: 650,
            tasksCompleted: 28,
            projectsOwned: 0
        ),
        User(
            name: "Emma Wilson",
            email: "emma.wilson@example.com",
            role: .member,
            coinsEarned: 420,
            tasksCompleted: 19,
            projectsOwned: 1
        )
    ]
    
    static var currentUser: User {
        User(
            name: "John Doe",
            email: "john.doe@example.com",
            role: .admin,
            coinsEarned: 2150,
            tasksCompleted: 67,
            projectsOwned: 4
        )
    }
}
