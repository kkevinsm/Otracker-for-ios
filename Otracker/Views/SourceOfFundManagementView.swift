//
//  SourceOfFundManagementView.swift
//  Otracker
//
//  Created by Kev on 09/07/25.
//


import SwiftUI
import SwiftData

struct SourceOfFundManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SourceOfFund.name) private var sources: [SourceOfFund]
    
    @State private var showingAddSourceAlert = false
    @State private var newSourceName = ""

    var body: some View {
        List {
            ForEach(sources) { source in
                Text(source.name)
            }
            .onDelete(perform: deleteSource)
        }
        .navigationTitle("source_management_title")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddSourceAlert.toggle()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("source_management_alert_title", isPresented: $showingAddSourceAlert) {
            TextField("source_management_alert_placeholder", text: $newSourceName)
                .autocorrectionDisabled()
            
            Button("source_management_alert_cancel_button", role: .cancel) {
                newSourceName = ""
            }
            
            Button("source_management_alert_save_button") {
                addSource()
            }
        } message: {
            Text("source_management_alert_message")
        }
    }

    private func addSource() {
        guard !newSourceName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let newSource = SourceOfFund(name: newSourceName)
        modelContext.insert(newSource)
        
        try? modelContext.save()
        
        newSourceName = ""
    }

    private func deleteSource(at offsets: IndexSet) {
        for offset in offsets {
            let source = sources[offset]
            modelContext.delete(source)
        }
    }
}
