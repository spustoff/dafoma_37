//
//  Task.swift
//  TaskOrbit Ano
//
//  Created by Assistant on 9/6/25.
//

import Foundation

struct Task: Identifiable, Codable, Hashable {
    let id = UUID()
    var title: String
    var description: String
    var isCompleted: Bool = false
    var priority: TaskPriority = .medium
    var dueDate: Date?
    var budget: Double?
    var actualCost: Double = 0.0
    var projectId: UUID?
    var assignedUserId: UUID?
    var createdAt: Date = Date()
    var completedAt: Date?
    var comments: [TaskComment] = []
    var tags: [String] = []
    
    enum TaskPriority: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case urgent = "Urgent"
        
        var color: String {
            switch self {
            case .low: return "blue"
            case .medium: return "green"
            case .high: return "orange"
            case .urgent: return "red"
            }
        }
    }
    
    var isOverBudget: Bool {
        guard let budget = budget else { return false }
        return actualCost > budget
    }
    
    var budgetVariance: Double {
        guard let budget = budget else { return 0 }
        return actualCost - budget
    }
    
    var profitMargin: Double {
        guard let budget = budget, budget > 0 else { return 0 }
        return ((budget - actualCost) / budget) * 100
    }
}

struct TaskComment: Identifiable, Codable, Hashable {
    let id = UUID()
    var text: String
    var authorId: UUID
    var authorName: String
    var createdAt: Date = Date()
}

extension Task {
    static let sampleTasks: [Task] = [
        Task(
            title: "Design App Logo",
            description: "Create a modern logo for TaskOrbit Ano that represents productivity and financial tracking",
            priority: .high,
            dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
            budget: 500.0,
            actualCost: 450.0,
            tags: ["design", "branding"]
        ),
        Task(
            title: "Implement User Authentication",
            description: "Set up secure user login and registration system",
            priority: .urgent,
            dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
            budget: 1200.0,
            actualCost: 800.0,
            tags: ["development", "security"]
        ),
        Task(
            title: "Market Research",
            description: "Analyze competitor apps and user preferences",
            isCompleted: true,
            priority: .medium,
            budget: 300.0,
            actualCost: 250.0,
            completedAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()),
            tags: ["research", "marketing"]
        )
    ]
}
