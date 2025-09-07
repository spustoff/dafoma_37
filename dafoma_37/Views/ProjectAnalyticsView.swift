//
//  ProjectAnalyticsView.swift
//  TaskOrbit Ano
//
//  Created by Assistant on 9/6/25.
//

import SwiftUI

struct ProjectAnalyticsView: View {
    @EnvironmentObject private var analyticsService: AnalyticsService
    @EnvironmentObject private var dataService: DataService
    @StateObject private var teamViewModel = TeamViewModel()
    
    @State private var selectedTimeFrame: TimeFrame = .month
    @State private var selectedProject: Project?
    @State private var showingProjectPicker = false
    
    enum TimeFrame: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
        
        var systemImage: String {
            switch self {
            case .week: return "calendar.day.timeline.left"
            case .month: return "calendar"
            case .quarter: return "calendar.badge.clock"
            case .year: return "calendar.badge.plus"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Header with project selector
                    headerSection
                    
                    // Key metrics cards
                    metricsSection
                    
                    // Financial overview
                    financialSection
                    
                    // Progress charts
                    progressSection
                    
                    // Team productivity
                    if let selectedProject = selectedProject {
                        teamProductivitySection(for: selectedProject)
                    }
                    
                    // Task distribution
                    taskDistributionSection
                }
                .padding()
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                            Button(action: { selectedTimeFrame = timeFrame }) {
                                Label(timeFrame.rawValue, systemImage: timeFrame.systemImage)
                            }
                        }
                    } label: {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.taskOrbitOrange)
                    }
                }
            }
        }
        .sheet(isPresented: $showingProjectPicker) {
            ProjectPickerView(selectedProject: $selectedProject)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Project Analytics")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primaryText)
                    
                    Text("Track performance and insights")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                Button(action: { showingProjectPicker = true }) {
                    HStack(spacing: 8) {
                        Text(selectedProject?.name ?? "All Projects")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.taskOrbitOrange)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.taskOrbitOrange)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.taskOrbitOrange.opacity(0.1))
                    .cornerRadius(20)
                }
            }
            
            // Time frame selector
            HStack(spacing: 12) {
                ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                    Button(action: { selectedTimeFrame = timeFrame }) {
                        Text(timeFrame.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(selectedTimeFrame == timeFrame ? .white : .taskOrbitOrange)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedTimeFrame == timeFrame ? Color.taskOrbitOrange : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.taskOrbitOrange, lineWidth: 1)
                                    )
                            )
                    }
                }
            }
        }
    }
    
    private var metricsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            MetricCard(
                title: "Total Tasks",
                value: "\(filteredAnalytics.reduce(0) { $0 + $1.totalTasks })",
                change: "+12%",
                changeType: .positive,
                icon: "list.bullet",
                color: .blue
            )
            
            MetricCard(
                title: "Completed",
                value: "\(filteredAnalytics.reduce(0) { $0 + $1.completedTasks })",
                change: "+8%",
                changeType: .positive,
                icon: "checkmark.circle",
                color: .profitGreen
            )
            
            MetricCard(
                title: "Total Budget",
                value: formatCurrency(filteredAnalytics.reduce(0) { $0 + $1.totalBudget }),
                change: "-5%",
                changeType: .negative,
                icon: "dollarsign.circle",
                color: .taskOrbitOrange
            )
            
            MetricCard(
                title: "Profit Margin",
                value: "\(Int(avgProfitMargin))%",
                change: "+3%",
                changeType: .positive,
                icon: "chart.line.uptrend.xyaxis",
                color: .purple
            )
        }
    }
    
    private var financialSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Financial Overview")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primaryText)
            
            VStack(spacing: 16) {
                // Budget vs Actual Summary
                VStack(spacing: 12) {
                    ForEach(filteredAnalytics.prefix(3)) { analytics in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(analytics.projectName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primaryText)
                                
                                HStack(spacing: 16) {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 8, height: 8)
                                        Text("Budget: \(formatCurrency(analytics.totalBudget))")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondaryText)
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Color.taskOrbitOrange)
                                            .frame(width: 8, height: 8)
                                        Text("Actual: \(formatCurrency(analytics.actualCost))")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondaryText)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            Text("\(Int(analytics.profitMargin))%")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(analytics.profitMargin >= 0 ? .profitGreen : .lossRed)
                        }
                        .padding()
                        .background(Color.taskOrbitTertiary)
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.taskOrbitSecondaryBackground)
                .cornerRadius(16)
                
                // Monthly spending summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Monthly Spending")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                        ForEach(analyticsService.financialSummary.monthlySpending.suffix(6)) { spending in
                            VStack(spacing: 4) {
                                Text(spending.month.prefix(3))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondaryText)
                                
                                Text(formatCurrency(spending.amount))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primaryText)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.taskOrbitSecondaryBackground)
                .cornerRadius(16)
            }
        }
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress Overview")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primaryText)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 16) {
                ForEach(filteredAnalytics.prefix(3)) { analytics in
                    ProjectProgressCard(analytics: analytics)
                }
            }
        }
    }
    
    private func teamProductivitySection(for project: Project) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Team Productivity")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primaryText)
            
            let productivity = teamViewModel.getTeamProductivity(for: project)
            
            VStack(spacing: 12) {
                ForEach(productivity.memberProductivity) { member in
                    TeamMemberCard(member: member)
                }
            }
        }
    }
    
    private var taskDistributionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Task Distribution")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primaryText)
            
            VStack(spacing: 12) {
                ForEach(Task.TaskPriority.allCases, id: \.self) { priority in
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(priorityColor(priority))
                                .frame(width: 12, height: 12)
                            
                            Text(priority.rawValue)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primaryText)
                        }
                        
                        Spacer()
                        
                        Text("\(taskCountByPriority[priority] ?? 0)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primaryText)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.taskOrbitTertiary)
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(Color.taskOrbitSecondaryBackground)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Computed Properties
    private var filteredAnalytics: [ProjectAnalytics] {
        if let selectedProject = selectedProject {
            return analyticsService.projectAnalytics.filter { $0.projectId == selectedProject.id }
        }
        return analyticsService.projectAnalytics
    }
    
    private var avgProfitMargin: Double {
        let margins = filteredAnalytics.map { $0.profitMargin }
        return margins.isEmpty ? 0 : margins.reduce(0, +) / Double(margins.count)
    }
    
    private var taskCountByPriority: [Task.TaskPriority: Int] {
        var counts: [Task.TaskPriority: Int] = [:]
        
        let tasks = selectedProject != nil 
            ? dataService.getTasksForProject(selectedProject!.id)
            : dataService.tasks
            
        for priority in Task.TaskPriority.allCases {
            counts[priority] = tasks.filter { $0.priority == priority }.count
        }
        
        return counts
    }
    
    // MARK: - Helper Methods
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
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
struct MetricCard: View {
    let title: String
    let value: String
    let change: String
    let changeType: ChangeType
    let icon: String
    let color: Color
    
    enum ChangeType {
        case positive, negative, neutral
        
        var color: Color {
            switch self {
            case .positive: return .profitGreen
            case .negative: return .lossRed
            case .neutral: return .neutralGray
            }
        }
        
        var icon: String {
            switch self {
            case .positive: return "arrow.up"
            case .negative: return "arrow.down"
            case .neutral: return "minus"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: changeType.icon)
                        .font(.system(size: 10))
                    Text(change)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(changeType.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primaryText)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondaryText)
            }
        }
        .padding()
        .background(Color.taskOrbitSecondaryBackground)
        .cornerRadius(16)
    }
}

struct ProjectProgressCard: View {
    let analytics: ProjectAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(analytics.projectName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Text("\(Int(analytics.progress * 100))%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.taskOrbitOrange)
            }
            
            ProgressView(value: analytics.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .taskOrbitOrange))
            
            HStack {
                Text("\(analytics.completedTasks)/\(analytics.totalTasks) tasks")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondaryText)
                
                Spacer()
                
                Text("Budget: \(formatCurrency(analytics.totalBudget))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondaryText)
            }
        }
        .padding()
        .background(Color.taskOrbitSecondaryBackground)
        .cornerRadius(12)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

struct TeamMemberCard: View {
    let member: UserProductivitySummary
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.taskOrbitOrange)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(member.user.initials)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(member.user.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Text("\(member.completedTasks)/\(member.totalTasks) tasks completed")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(member.completionRate))%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.taskOrbitOrange)
                
                Text("completion")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondaryText)
            }
        }
        .padding()
        .background(Color.taskOrbitSecondaryBackground)
        .cornerRadius(12)
    }
}

struct ProjectPickerView: View {
    @Binding var selectedProject: Project?
    @EnvironmentObject private var dataService: DataService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    selectedProject = nil
                    dismiss()
                }) {
                    HStack {
                        Text("All Projects")
                            .foregroundColor(.primaryText)
                        
                        Spacer()
                        
                        if selectedProject == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.taskOrbitOrange)
                        }
                    }
                }
                
                ForEach(dataService.projects) { project in
                    Button(action: {
                        selectedProject = project
                        dismiss()
                    }) {
                        HStack {
                            Text(project.name)
                                .foregroundColor(.primaryText)
                            
                            Spacer()
                            
                            if selectedProject?.id == project.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.taskOrbitOrange)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ProjectAnalyticsView()
        .environmentObject(AnalyticsService.shared)
        .environmentObject(DataService.shared)
}
