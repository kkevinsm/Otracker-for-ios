//
//  SettingsView.swift
//  Otracker
//
//  Created by Kev on 09/07/25.
//


import SwiftUI
import SwiftData

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink(destination: CategoryManagementView()) {
                    Label("settings_manage_categories", systemImage: "tag.fill")
                }
                NavigationLink(destination: SourceOfFundManagementView()) {
                    Label("settings_manage_sources", systemImage: "creditcard.fill")
                }
            }
            .navigationTitle("tab_settings")
        }
    }
}
