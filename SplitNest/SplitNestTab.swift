//
//  SplitNestTab.swift
//  SplitNest
//
//  Created by Bryan on 12/2/25.
//


// RootTabView.swift

import SwiftUI

enum SplitNestTab: Hashable {
    case home
    case expenses
    case budget
    case chores
    case lists
}

struct RootTabView: View {
    @State private var selectedTab: SplitNestTab = .home

    var body: some View {
        ZStack {
            SplitNestTheme.backgroundGradient
                .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView()
                }
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(SplitNestTab.home)

                NavigationStack {
                    ExpensesView()
                }
                .tabItem {
                    Label("Expenses", systemImage: "creditcard.fill")
                }
                .tag(SplitNestTab.expenses)

                NavigationStack {
                    MonthlyBudgetView()
                }
                .tabItem {
                    Label("Budget", systemImage: "chart.pie.fill")
                }
                .tag(SplitNestTab.budget)

                NavigationStack {
                    ChoresView()
                }
                .tabItem {
                    Label("Chores", systemImage: "checkmark.square.fill")
                }
                .tag(SplitNestTab.chores)

                NavigationStack {
                    ListsView()
                }
                .tabItem {
                    Label("Lists", systemImage: "list.bullet.rectangle.portrait.fill")
                }
                .tag(SplitNestTab.lists)

            }
            .tint(SplitNestTheme.primary)
#if os(iOS)
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
#endif
        }
    }
}
