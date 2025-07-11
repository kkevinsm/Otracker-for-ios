import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("tab_summary", systemImage: "chart.pie.fill")
                }
            
            TransactionHistoryView()
                .tabItem {
                    Label("tab_history", systemImage: "list.bullet")
                }
            
            BudgetView()
                .tabItem {
                    Label("tab_budget", systemImage: "target")
                }
            
            BillsView()
                .tabItem {
                    Label("tab_bills", systemImage: "calendar")
                }
            
            SettingsView()
                    .tabItem {
                        Label("tab_settings", systemImage: "gear")
                    }
        }
    }
}

//
//  MainTabView.swift
//  Otracker
//
//  Created by Kev on 09/07/25.
//

