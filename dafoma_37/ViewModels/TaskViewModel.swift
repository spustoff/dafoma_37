//
//  TaskViewModel.swift
//  TaskOrbit Ano
//
//  Created by Assistant on 9/6/25.
//

import Foundation
import Combine

class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var filteredTasks: [Task] = []
    @Published var selectedProject: Project?
    @Published var searchText: String = ""
    @Published var selectedPriority: Task.TaskPriority?
    @Published var showCompletedTasks: Bool = true
    @Published var sortOption: TaskSortOption = .dueDate
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let dataService = DataService.shared
    private var cancellables = Set<AnyCancellable>()
    
    enum TaskSortOption: String, CaseIterable {
        case dueDate = "Due Date"
        case priority = "Priority"
        case title = "Title"
        case created = "Created"
        case budget = "Budget"
        
        var systemImage: String {
            switch self {
            case .dueDate: return "calendar"
            case .priority: return "exclamationmark.triangle"
            case .title: return "textformat"
            case .created: return "clock"
            case .budget: return "dollarsign.circle"
            }
        }
    }
    
    init() {
        setupBindings()
        loadTasks()
    }
    
    private func setupBindings() {
        // Subscribe to data service tasks
        dataService.$tasks
            .assign(to: \.tasks, on: self)
            .store(in: &cancellables)
        
        // Filter tasks when any filter criteria changes
        Publishers.CombineLatest4(
            $tasks,
            $searchText,
            $selectedPriority,
            $showCompletedTasks
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .map { [weak self] tasks, searchText, priority, showCompleted in
            self?.filterTasks(tasks, searchText: searchText, priority: priority, showCompleted: showCompleted) ?? []
        }
        .assign(to: \.filteredTasks, on: self)
        .store(in: &cancellables)
        
        // Sort tasks when sort option changes
        Publishers.CombineLatest(
            $filteredTasks,
            $sortOption
        )
        .map { [weak self] tasks, sortOption in
            self?.sortTasks(tasks, by: sortOption) ?? []
        }
        .assign(to: \.filteredTasks, on: self)
        .store(in: &cancellables)
    }
    
    private func loadTasks() {
        isLoading = true
        
        // Simulate loading delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
        }
    }
    
    // MARK: - Task Operations
    func addTask(title: String, description: String, priority: Task.TaskPriority = .medium, 
                dueDate: Date? = nil, budget: Double? = nil, projectId: UUID? = nil) {
        let newTask = Task(
            title: title,
            description: description,
            priority: priority,
            dueDate: dueDate,
            budget: budget,
            projectId: projectId ?? selectedProject?.id,
            assignedUserId: dataService.currentUser.id
        )
        
        dataService.addTask(newTask)
    }
    
    func updateTask(_ task: Task) {
        dataService.updateTask(task)
    }
    
    func deleteTask(_ task: Task) {
        dataService.deleteTask(task)
    }
    
    func toggleTaskCompletion(_ task: Task) {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        
        if updatedTask.isCompleted {
            updatedTask.completedAt = Date()
        } else {
            updatedTask.completedAt = nil
        }
        
        updateTask(updatedTask)
    }
    
    func addComment(to task: Task, text: String) {
        let comment = TaskComment(
            text: text,
            authorId: dataService.currentUser.id,
            authorName: dataService.currentUser.displayName
        )
        
        dataService.addComment(to: task.id, comment: comment)
    }
    
    func updateTaskBudget(_ task: Task, budget: Double?, actualCost: Double) {
        var updatedTask = task
        updatedTask.budget = budget
        updatedTask.actualCost = actualCost
        updateTask(updatedTask)
    }
    
    // MARK: - Filtering and Sorting
    private func filterTasks(_ tasks: [Task], searchText: String, priority: Task.TaskPriority?, showCompleted: Bool) -> [Task] {
        var filtered = tasks
        
        // Filter by completion status
        if !showCompleted {
            filtered = filtered.filter { !$0.isCompleted }
        }
        
        // Filter by priority
        if let priority = priority {
            filtered = filtered.filter { $0.priority == priority }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                task.description.localizedCaseInsensitiveContains(searchText) ||
                task.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Filter by selected project
        if let selectedProject = selectedProject {
            filtered = filtered.filter { $0.projectId == selectedProject.id }
        }
        
        return filtered
    }
    
    private func sortTasks(_ tasks: [Task], by sortOption: TaskSortOption) -> [Task] {
        switch sortOption {
        case .dueDate:
            return tasks.sorted { task1, task2 in
                // Tasks with due dates come first, then by due date
                switch (task1.dueDate, task2.dueDate) {
                case (nil, nil): return task1.createdAt > task2.createdAt
                case (nil, _): return false
                case (_, nil): return true
                case (let date1?, let date2?): return date1 < date2
                }
            }
        case .priority:
            return tasks.sorted { task1, task2 in
                let priorities: [Task.TaskPriority] = [.urgent, .high, .medium, .low]
                let index1 = priorities.firstIndex(of: task1.priority) ?? priorities.count
                let index2 = priorities.firstIndex(of: task2.priority) ?? priorities.count
                return index1 < index2
            }
        case .title:
            return tasks.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .created:
            return tasks.sorted { $0.createdAt > $1.createdAt }
        case .budget:
            return tasks.sorted { task1, task2 in
                let budget1 = task1.budget ?? 0
                let budget2 = task2.budget ?? 0
                return budget1 > budget2
            }
        }
    }
    
    // MARK: - Computed Properties
    var completedTasksCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    var pendingTasksCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }
    
    var overdueTasks: [Task] {
        let now = Date()
        return tasks.filter { task in
            guard let dueDate = task.dueDate, !task.isCompleted else { return false }
            return dueDate < now
        }
    }
    
    var upcomingTasks: [Task] {
        let calendar = Calendar.current
        let now = Date()
        let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: now) ?? now
        
        return tasks.filter { task in
            guard let dueDate = task.dueDate, !task.isCompleted else { return false }
            return dueDate >= now && dueDate <= nextWeek
        }
    }
    
    var totalBudget: Double {
        tasks.compactMap { $0.budget }.reduce(0, +)
    }
    
    var totalActualCost: Double {
        tasks.map { $0.actualCost }.reduce(0, +)
    }
    
    var budgetVariance: Double {
        totalBudget - totalActualCost
    }
    
    var overBudgetTasks: [Task] {
        tasks.filter { $0.isOverBudget }
    }
    
    // MARK: - Utility Methods
    func clearFilters() {
        searchText = ""
        selectedPriority = nil
        selectedProject = nil
        showCompletedTasks = true
        sortOption = .dueDate
    }
    
    func refreshTasks() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
        }
    }
    
    func getTasksForProject(_ project: Project) -> [Task] {
        return dataService.getTasksForProject(project.id)
    }
    
    func getProjectForTask(_ task: Task) -> Project? {
        guard let projectId = task.projectId else { return nil }
        return dataService.projects.first { $0.id == projectId }
    }
    
    func canEditTask(_ task: Task) -> Bool {
        let currentUser = dataService.currentUser
        
        // User can edit if they're the assignee, project owner, or have admin rights
        return task.assignedUserId == currentUser.id ||
               currentUser.role == .admin ||
               (currentUser.role == .projectManager && getProjectForTask(task)?.ownerId == currentUser.id)
    }
}
