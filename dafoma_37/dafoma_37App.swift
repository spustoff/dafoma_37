//
//  TaskOrbitApp.swift
//  TaskOrbit Ano
//
//  Created by Assistant on 9/6/25.
//

import SwiftUI

@main
struct TaskOrbitApp: App {
    @StateObject private var dataService = DataService.shared
    @StateObject private var analyticsService = AnalyticsService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataService)
                .environmentObject(analyticsService)
                .preferredColorScheme(dataService.currentUser.preferences.enableDarkMode ? .dark : nil)
        }
    }
}
