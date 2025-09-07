//
//  Project.swift
//  TaskOrbit Ano
//
//  Created by Assistant on 9/6/25.
//

import Foundation

struct Project: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var description: String
    var status: ProjectStatus = .active
    var budget: Double?
    var actualCost: Double = 0.0
    var startDate: Date = Date()
    var endDate: Date?
    var ownerId: UUID
    var memberIds: [UUID] = []
    var taskIds: [UUID] = []
    var createdAt: Date = Date()
    var color: String = "#FF3C00" // Default TaskOrbit orange
    
    enum ProjectStatus: String, CaseIterable, Codable {
        case planning = "Planning"
        case active = "Active"
        case onHold = "On Hold"
        case completed = "Completed"
        case cancelled = "Cancelled"
        
        var color: String {
            switch self {
            case .planning: return "blue"
            case .active: return "green"
            case .onHold: return "yellow"
            case .completed: return "purple"
            case .cancelled: return "red"
            }
        }
    }
    
    var totalBudget: Double {
        budget ?? 0.0
    }
    
    var isOverBudget: Bool {
        guard let budget = budget else { return false }
        return actualCost > budget
    }
    
    var budgetUtilization: Double {
        guard let budget = budget, budget > 0 else { return 0 }
        return (actualCost / budget) * 100
    }
    
    var profitMargin: Double {
        guard let budget = budget, budget > 0 else { return 0 }
        return ((budget - actualCost) / budget) * 100
    }
    
    var isCompleted: Bool {
        status == .completed
    }
    
    var progress: Double {
        // This would be calculated based on completed tasks
        // For now, return a placeholder based on status
        switch status {
        case .planning: return 0.0
        case .active: return 0.6
        case .onHold: return 0.3
        case .completed: return 1.0
        case .cancelled: return 0.0
        }
    }
}

extension Project {
    static let sampleProjects: [Project] = [
        Project(
            name: "TaskOrbit Mobile App",
            description: "Develop a comprehensive task management app with financial tracking",
            budget: 15000.0,
            actualCost: 8500.0,
            startDate: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 2, to: Date()),
            ownerId: UUID(),
            color: "#FF3C00"
        ),
        Project(
            name: "Marketing Campaign",
            description: "Launch campaign for app store release",
            status: .planning,
            budget: 5000.0,
            actualCost: 1200.0,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
            ownerId: UUID(),
            color: "#007AFF"
        ),
        Project(
            name: "User Research Study",
            description: "Conduct user interviews and usability testing",
            status: .completed,
            budget: 2000.0,
            actualCost: 1800.0,
            startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
            endDate: Calendar.current.date(byAdding: .month, value: -1, to: Date()),
            ownerId: UUID(),
            color: "#34C759"
        )
    ]
}
