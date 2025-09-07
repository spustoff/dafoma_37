//
//  AnalyticsService.swift
//  TaskOrbit Ano
//
//  Created by Assistant on 9/6/25.
//

import Foundation
import Combine

class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    @Published var projectAnalytics: [ProjectAnalytics] = []
    @Published var userProductivity: UserProductivity = UserProductivity()
    @Published var financialSummary: FinancialSummary = FinancialSummary()
    
    private let dataService = DataService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupSubscriptions()
        calculateAnalytics()
    }
    
    private func setupSubscriptions() {
        // Update analytics when data changes
        Publishers.CombineLatest3(
            dataService.$tasks,
            dataService.$projects,
            dataService.$currentUser
        )
        .sink { [weak self] _, _, _ in
            self?.calculateAnalytics()
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Analytics Calculation
    private func calculateAnalytics() {
        calculateProjectAnalytics()
        calculateUserProductivity()
        calculateFinancialSummary()
    }
    
    private func calculateProjectAnalytics() {
        projectAnalytics = dataService.projects.map { project in
            let projectTasks = dataService.getTasksForProject(project.id)
            let completedTasks = projectTasks.filter { $0.isCompleted }
            
            let totalBudget = projectTasks.compactMap { $0.budget }.reduce(0, +)
            let totalActualCost = projectTasks.map { $0.actualCost }.reduce(0, +)
            
            let progress = projectTasks.isEmpty ? 0.0 : Double(completedTasks.count) / Double(projectTasks.count)
            
            return ProjectAnalytics(
                projectId: project.id,
                projectName: project.name,
                totalTasks: projectTasks.count,
                completedTasks: completedTasks.count,
                progress: progress,
                totalBudget: totalBudget,
                actualCost: totalActualCost,
                profitMargin: calculateProfitMargin(budget: totalBudget, actualCost: totalActualCost),
                tasksByPriority: calculateTasksByPriority(projectTasks),
                completionTrend: calculateCompletionTrend(completedTasks),
                budgetUtilization: calculateBudgetUtilization(budget: totalBudget, actualCost: totalActualCost)
            )
        }
    }
    
    private func calculateUserProductivity() {
        let user = dataService.currentUser
        let userTasks = dataService.getTasksForUser(user.id)
        let completedTasks = userTasks.filter { $0.isCompleted }
        
        let thisWeekTasks = completedTasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return Calendar.current.isDate(completedAt, equalTo: Date(), toGranularity: .weekOfYear)
        }
        
        let thisMonthTasks = completedTasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return Calendar.current.isDate(completedAt, equalTo: Date(), toGranularity: .month)
        }
        
        userProductivity = UserProductivity(
            totalTasksCompleted: completedTasks.count,
            tasksThisWeek: thisWeekTasks.count,
            tasksThisMonth: thisMonthTasks.count,
            averageTasksPerDay: calculateAverageTasksPerDay(completedTasks),
            coinsEarned: user.coinsEarned,
            productivityScore: user.productivityScore,
            streakDays: calculateStreakDays(completedTasks),
            completionRate: calculateCompletionRate(userTasks)
        )
    }
    
    private func calculateFinancialSummary() {
        let allTasks = dataService.tasks
        let allProjects = dataService.projects
        
        let totalBudget = allTasks.compactMap { $0.budget }.reduce(0, +) +
                         allProjects.compactMap { $0.budget }.reduce(0, +)
        
        let totalActualCost = allTasks.map { $0.actualCost }.reduce(0, +) +
                             allProjects.map { $0.actualCost }.reduce(0, +)
        
        let profit = totalBudget - totalActualCost
        let profitMargin = totalBudget > 0 ? (profit / totalBudget) * 100 : 0
        
        let overBudgetProjects = allProjects.filter { $0.isOverBudget }.count
        let overBudgetTasks = allTasks.filter { $0.isOverBudget }.count
        
        financialSummary = FinancialSummary(
            totalBudget: totalBudget,
            totalActualCost: totalActualCost,
            totalProfit: profit,
            profitMargin: profitMargin,
            overBudgetItems: overBudgetProjects + overBudgetTasks,
            averageCostPerTask: allTasks.isEmpty ? 0 : totalActualCost / Double(allTasks.count),
            budgetUtilization: totalBudget > 0 ? (totalActualCost / totalBudget) * 100 : 0,
            monthlySpending: calculateMonthlySpending(allTasks + allProjects.map { project in
                Task(title: project.name, description: "", actualCost: project.actualCost)
            })
        )
    }
    
    // MARK: - Helper Methods
    private func calculateProfitMargin(budget: Double, actualCost: Double) -> Double {
        guard budget > 0 else { return 0 }
        return ((budget - actualCost) / budget) * 100
    }
    
    private func calculateTasksByPriority(_ tasks: [Task]) -> [String: Int] {
        var priorityCount: [String: Int] = [:]
        
        for priority in Task.TaskPriority.allCases {
            priorityCount[priority.rawValue] = tasks.filter { $0.priority == priority }.count
        }
        
        return priorityCount
    }
    
    private func calculateCompletionTrend(_ completedTasks: [Task]) -> [CompletionTrendPoint] {
        let calendar = Calendar.current
        let now = Date()
        var trendPoints: [CompletionTrendPoint] = []
        
        // Calculate completion trend for the last 7 days
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            let completedOnDate = completedTasks.filter { task in
                guard let completedAt = task.completedAt else { return false }
                return calendar.isDate(completedAt, inSameDayAs: date)
            }.count
            
            trendPoints.append(CompletionTrendPoint(
                date: date,
                completedTasks: completedOnDate
            ))
        }
        
        return trendPoints.reversed()
    }
    
    private func calculateBudgetUtilization(budget: Double, actualCost: Double) -> Double {
        guard budget > 0 else { return 0 }
        return (actualCost / budget) * 100
    }
    
    private func calculateAverageTasksPerDay(_ completedTasks: [Task]) -> Double {
        guard !completedTasks.isEmpty else { return 0 }
        
        let sortedTasks = completedTasks.compactMap { $0.completedAt }.sorted()
        guard let firstDate = sortedTasks.first,
              let lastDate = sortedTasks.last else { return 0 }
        
        let daysDifference = Calendar.current.dateComponents([.day], from: firstDate, to: lastDate).day ?? 1
        return Double(completedTasks.count) / Double(max(daysDifference, 1))
    }
    
    private func calculateStreakDays(_ completedTasks: [Task]) -> Int {
        let calendar = Calendar.current
        let now = Date()
        var streakDays = 0
        
        // Check consecutive days with completed tasks
        for i in 0..<30 { // Check last 30 days
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            let hasCompletedTask = completedTasks.contains { task in
                guard let completedAt = task.completedAt else { return false }
                return calendar.isDate(completedAt, inSameDayAs: date)
            }
            
            if hasCompletedTask {
                streakDays += 1
            } else {
                break
            }
        }
        
        return streakDays
    }
    
    private func calculateCompletionRate(_ tasks: [Task]) -> Double {
        guard !tasks.isEmpty else { return 0 }
        let completedCount = tasks.filter { $0.isCompleted }.count
        return (Double(completedCount) / Double(tasks.count)) * 100
    }
    
    private func calculateMonthlySpending(_ items: [Task]) -> [MonthlySpending] {
        let calendar = Calendar.current
        let now = Date()
        var monthlyData: [MonthlySpending] = []
        
        // Calculate spending for the last 6 months
        for i in 0..<6 {
            let date = calendar.date(byAdding: .month, value: -i, to: now) ?? now
            let monthItems = items.filter { item in
                calendar.isDate(item.createdAt, equalTo: date, toGranularity: .month)
            }
            
            let totalSpending = monthItems.map { $0.actualCost }.reduce(0, +)
            let monthName = DateFormatter().monthSymbols[calendar.component(.month, from: date) - 1]
            
            monthlyData.append(MonthlySpending(
                month: monthName,
                amount: totalSpending,
                date: date
            ))
        }
        
        return monthlyData.reversed()
    }
}

// MARK: - Analytics Data Structures
struct ProjectAnalytics: Identifiable {
    let id = UUID()
    let projectId: UUID
    let projectName: String
    let totalTasks: Int
    let completedTasks: Int
    let progress: Double
    let totalBudget: Double
    let actualCost: Double
    let profitMargin: Double
    let tasksByPriority: [String: Int]
    let completionTrend: [CompletionTrendPoint]
    let budgetUtilization: Double
}

struct UserProductivity {
    let totalTasksCompleted: Int
    let tasksThisWeek: Int
    let tasksThisMonth: Int
    let averageTasksPerDay: Double
    let coinsEarned: Int
    let productivityScore: Double
    let streakDays: Int
    let completionRate: Double
    
    init() {
        self.totalTasksCompleted = 0
        self.tasksThisWeek = 0
        self.tasksThisMonth = 0
        self.averageTasksPerDay = 0
        self.coinsEarned = 0
        self.productivityScore = 0
        self.streakDays = 0
        self.completionRate = 0
    }
    
    init(totalTasksCompleted: Int, tasksThisWeek: Int, tasksThisMonth: Int,
         averageTasksPerDay: Double, coinsEarned: Int, productivityScore: Double,
         streakDays: Int, completionRate: Double) {
        self.totalTasksCompleted = totalTasksCompleted
        self.tasksThisWeek = tasksThisWeek
        self.tasksThisMonth = tasksThisMonth
        self.averageTasksPerDay = averageTasksPerDay
        self.coinsEarned = coinsEarned
        self.productivityScore = productivityScore
        self.streakDays = streakDays
        self.completionRate = completionRate
    }
}

struct FinancialSummary {
    let totalBudget: Double
    let totalActualCost: Double
    let totalProfit: Double
    let profitMargin: Double
    let overBudgetItems: Int
    let averageCostPerTask: Double
    let budgetUtilization: Double
    let monthlySpending: [MonthlySpending]
    
    init() {
        self.totalBudget = 0
        self.totalActualCost = 0
        self.totalProfit = 0
        self.profitMargin = 0
        self.overBudgetItems = 0
        self.averageCostPerTask = 0
        self.budgetUtilization = 0
        self.monthlySpending = []
    }
    
    init(totalBudget: Double, totalActualCost: Double, totalProfit: Double,
         profitMargin: Double, overBudgetItems: Int, averageCostPerTask: Double,
         budgetUtilization: Double, monthlySpending: [MonthlySpending]) {
        self.totalBudget = totalBudget
        self.totalActualCost = totalActualCost
        self.totalProfit = totalProfit
        self.profitMargin = profitMargin
        self.overBudgetItems = overBudgetItems
        self.averageCostPerTask = averageCostPerTask
        self.budgetUtilization = budgetUtilization
        self.monthlySpending = monthlySpending
    }
}

struct CompletionTrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let completedTasks: Int
}

struct MonthlySpending: Identifiable {
    let id = UUID()
    let month: String
    let amount: Double
    let date: Date
}
