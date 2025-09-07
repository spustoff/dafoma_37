//
//  TaskDetailView.swift
//  TaskOrbit Ano
//
//  Created by Assistant on 9/6/25.
//

import SwiftUI

struct TaskDetailView: View {
    @Binding var task: Task
    @EnvironmentObject private var dataService: DataService
    @StateObject private var taskViewModel = TaskViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEditSheet = false
    @State private var newComment = ""
    @State private var showingBudgetSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Section
                    headerSection
                    
                    // Progress and Status
                    statusSection
                    
                    // Financial Information
                    if task.budget != nil || task.actualCost > 0 {
                        financialSection
                    }
                    
                    // Description
                    descriptionSection
                    
                    // Tags
                    if !task.tags.isEmpty {
                        tagsSection
                    }
                    
                    // Comments Section
                    commentsSection
                }
                .padding()
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.taskOrbitOrange)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: { showingEditSheet = true }) {
                            Label("Edit Task", systemImage: "pencil")
                        }
                        
                        Button(action: { showingBudgetSheet = true }) {
                            Label("Edit Budget", systemImage: "dollarsign.circle")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: { showingDeleteAlert = true }) {
                            Label("Delete Task", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.taskOrbitOrange)
                    }
                    .disabled(!taskViewModel.canEditTask(task))
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditTaskView(task: $task)
        }
        .sheet(isPresented: $showingBudgetSheet) {
            BudgetEditView(task: $task)
        }
        .alert("Delete Task", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                taskViewModel.deleteTask(task)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this task? This action cannot be undone.")
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primaryText)
                    
                    if let project = taskViewModel.getProjectForTask(task) {
                        Text(project.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondaryText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.taskOrbitSecondaryBackground)
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    taskViewModel.toggleTaskCompletion(task)
                    task.isCompleted.toggle()
                    if task.isCompleted {
                        task.completedAt = Date()
                    } else {
                        task.completedAt = nil
                    }
                }) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 28))
                        .foregroundColor(task.isCompleted ? .profitGreen : .gray)
                }
            }
            
            // Priority and Due Date
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(priorityColor(task.priority))
                        .frame(width: 8, height: 8)
                    
                    Text(task.priority.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primaryText)
                }
                
                if let dueDate = task.dueDate {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(.secondaryText)
                        
                        Text(dueDate, style: .date)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isOverdue ? .lossRed : .secondaryText)
                    }
                }
            }
        }
        .padding()
        .background(Color.taskOrbitSecondaryBackground)
        .cornerRadius(16)
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primaryText)
            
            HStack(spacing: 16) {
                StatusCard(
                    title: "Completion",
                    value: task.isCompleted ? "Complete" : "In Progress",
                    icon: task.isCompleted ? "checkmark.circle.fill" : "clock.fill",
                    color: task.isCompleted ? .profitGreen : .taskOrbitOrange
                )
                
                if let createdDate = Calendar.current.dateComponents([.day], from: task.createdAt, to: Date()).day {
                    StatusCard(
                        title: "Age",
                        value: "\(createdDate) days",
                        icon: "calendar",
                        color: .blue
                    )
                }
            }
        }
    }
    
    private var financialSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Financial Information")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primaryText)
            
            VStack(spacing: 12) {
                if let budget = task.budget {
                    FinancialRow(
                        title: "Budget",
                        amount: budget,
                        color: .blue
                    )
                }
                
                if task.actualCost > 0 {
                    FinancialRow(
                        title: "Actual Cost",
                        amount: task.actualCost,
                        color: task.isOverBudget ? .lossRed : .profitGreen
                    )
                }
                
                if let budget = task.budget, task.actualCost > 0 {
                    FinancialRow(
                        title: "Variance",
                        amount: task.budgetVariance,
                        color: task.budgetVariance >= 0 ? .profitGreen : .lossRed,
                        showSign: true
                    )
                    
                    // Progress bar for budget utilization
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Budget Utilization")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primaryText)
                            
                            Spacer()
                            
                            Text("\(Int((task.actualCost / budget) * 100))%")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primaryText)
                        }
                        
                        ProgressView(value: task.actualCost / budget)
                            .progressViewStyle(LinearProgressViewStyle(tint: task.isOverBudget ? .lossRed : .profitGreen))
                    }
                }
            }
            .padding()
            .background(Color.taskOrbitSecondaryBackground)
            .cornerRadius(12)
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primaryText)
            
            Text(task.description.isEmpty ? "No description provided" : task.description)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(task.description.isEmpty ? .secondaryText : .primaryText)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.taskOrbitSecondaryBackground)
                .cornerRadius(12)
        }
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primaryText)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(task.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.taskOrbitOrange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.taskOrbitOrange.opacity(0.1))
                        .cornerRadius(16)
                }
            }
        }
    }
    
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Comments")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primaryText)
            
            // Add comment section
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(Color.taskOrbitOrange)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(dataService.currentUser.initials)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        )
                    
                    TextField("Add a comment...", text: $newComment)
                        .lineLimit(3)
                        .padding()
                        .background(Color.taskOrbitSecondaryBackground)
                        .cornerRadius(12)
                }
                
                if !newComment.isEmpty {
                    HStack {
                        Spacer()
                        
                        Button("Post Comment") {
                            taskViewModel.addComment(to: task, text: newComment)
                            newComment = ""
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.taskOrbitOrange)
                        .cornerRadius(20)
                    }
                }
            }
            
            // Comments list
            LazyVStack(spacing: 16) {
                ForEach(task.comments) { comment in
                    CommentView(comment: comment)
                }
            }
        }
    }
    
    private var isOverdue: Bool {
        guard let dueDate = task.dueDate, !task.isCompleted else { return false }
        return dueDate < Date()
    }
    
    private func priorityColor(_ priority: Task.TaskPriority) -> Color {
        switch priority {
        case .low: return .priorityLow
        case .medium: return .priorityMedium
        case .high: return .priorityHigh
        case .urgent: return .priorityUrgent
        }
    }
}

// MARK: - Supporting Views
struct StatusCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.taskOrbitSecondaryBackground)
        .cornerRadius(12)
    }
}

struct FinancialRow: View {
    let title: String
    let amount: Double
    let color: Color
    let showSign: Bool
    
    init(title: String, amount: Double, color: Color, showSign: Bool = false) {
        self.title = title
        self.amount = amount
        self.color = color
        self.showSign = showSign
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primaryText)
            
            Spacer()
            
            Text(formattedAmount)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
        }
    }
    
    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        
        let formattedValue = formatter.string(from: NSNumber(value: abs(amount))) ?? "$0.00"
        
        if showSign {
            return amount >= 0 ? "+\(formattedValue)" : "-\(formattedValue)"
        } else {
            return formattedValue
        }
    }
}

struct CommentView: View {
    let comment: TaskComment
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.blue)
                .frame(width: 32, height: 32)
                .overlay(
                    Text(comment.authorName.prefix(2).uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.authorName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                    
                    Text(comment.createdAt, style: .relative)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondaryText)
                }
                
                Text(comment.text)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.primaryText)
            }
        }
        .padding()
        .background(Color.taskOrbitSecondaryBackground)
        .cornerRadius(12)
    }
}

// MARK: - Edit Views (Placeholder implementations)
struct EditTaskView: View {
    @Binding var task: Task
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Task Title", text: $task.title)
                    TextField("Description", text: $task.description)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
}

struct BudgetEditView: View {
    @Binding var task: Task
    @Environment(\.dismiss) private var dismiss
    @State private var budgetString = ""
    @State private var actualCostString = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Budget Information") {
                    TextField("Budget", text: $budgetString)
                        .keyboardType(.decimalPad)
                    
                    TextField("Actual Cost", text: $actualCostString)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        if let budget = Double(budgetString) {
                            task.budget = budget
                        }
                        if let actualCost = Double(actualCostString) {
                            task.actualCost = actualCost
                        }
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .onAppear {
            budgetString = task.budget?.description ?? ""
            actualCostString = task.actualCost.description
        }
    }
}

#Preview {
    TaskDetailView(task: .constant(Task.sampleTasks[0]))
        .environmentObject(DataService.shared)
}
