//
//  OnboardingView.swift
//  TaskOrbit Ano
//
//  Created by Assistant on 9/6/25.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var showingGetStarted = false
    
    private let onboardingPages = [
        OnboardingPage(
            title: "Welcome to TaskOrbit Ano",
            description: "Manage your tasks and projects with financial insights. Track budgets, earn rewards, and boost productivity.",
            imageName: "rocket.fill",
            backgroundColor: Color.taskOrbitOrange
        ),
        OnboardingPage(
            title: "Financial Tracking",
            description: "Associate budgets with tasks and projects. Monitor spending, track profitability, and make informed decisions.",
            imageName: "dollarsign.circle.fill",
            backgroundColor: Color.profitGreen
        ),
        OnboardingPage(
            title: "Team Collaboration",
            description: "Invite team members, assign tasks, and communicate through integrated comments and project updates.",
            imageName: "person.3.fill",
            backgroundColor: Color.blue
        ),
        OnboardingPage(
            title: "Gamified Rewards",
            description: "Earn coins for completing tasks and achieving milestones. Turn productivity into a rewarding experience.",
            imageName: "star.fill",
            backgroundColor: Color.purple
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [onboardingPages[currentPage].backgroundColor.opacity(0.3), Color.taskOrbitBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        Rectangle()
                            .frame(width: currentPage == index ? 24 : 8, height: 4)
                            .foregroundColor(currentPage == index ? Color.taskOrbitOrange : Color.gray.opacity(0.3))
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal)
                
                // Content
                TabView(selection: $currentPage) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        OnboardingPageView(page: onboardingPages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Navigation buttons
                HStack {
                    if currentPage > 0 {
                        Button("Previous") {
                            withAnimation(.easeInOut) {
                                currentPage -= 1
                            }
                        }
                        .foregroundColor(.taskOrbitOrange)
                        .font(.system(size: 16, weight: .medium))
                    }
                    
                    Spacer()
                    
                    if currentPage < onboardingPages.count - 1 {
                        Button("Next") {
                            withAnimation(.easeInOut) {
                                currentPage += 1
                            }
                        }
                        .foregroundColor(.taskOrbitOrange)
                        .font(.system(size: 16, weight: .medium))
                    } else {
                        Button(action: {
                            hasCompletedOnboarding = true
                        }) {
                            Text("Get Started")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.taskOrbitGradient)
                                )
                        }
                        .frame(maxWidth: 200)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // Auto-advance pages every 5 seconds if user is inactive
            Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { timer in
                if currentPage < onboardingPages.count - 1 && !showingGetStarted {
                    withAnimation(.easeInOut) {
                        currentPage += 1
                    }
                } else {
                    timer.invalidate()
                }
            }
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(page.backgroundColor.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: page.imageName)
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(page.backgroundColor)
            }
            
            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let backgroundColor: Color
}

#Preview {
    OnboardingView()
}
