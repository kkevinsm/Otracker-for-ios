//
//  CategoryManagementView.swift
//  Otracker
//
//  Created by Kev on 09/07/25.
//


import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var categories: [Category]
    
    @State private var showingAddCategoryAlert = false
    @State private var newCategoryName = ""

    var body: some View {
        List {
            ForEach(categories) { category in
                DisclosureGroup(category.name) {
                    ForEach(category.subcategories.sorted(by: { $0.name < $1.name })) { subcategory in
                        Text(subcategory.name)
                    }
                    .onDelete { indexSet in
                        deleteSubcategory(from: category, at: indexSet)
                    }
                    
                    Button("category_management_add_subcategory_button") {
                    }
                }
            }
            .onDelete(perform: deleteCategory)
        }
        .navigationTitle("category_management_title")
        .toolbar {
            Button { showingAddCategoryAlert.toggle() } label: { Image(systemName: "plus") }
        }
        .alert("category_management_alert_title", isPresented: $showingAddCategoryAlert) {
            TextField("category_management_alert_placeholder", text: $newCategoryName)
            Button("category_management_alert_cancel_button", role: .cancel) { newCategoryName = "" }
            Button("category_management_alert_save_button") { addCategory() }
        }
    }
    
    private func addCategory() {
        guard !newCategoryName.isEmpty else { return }
        let newCategory = Category(name: newCategoryName)
        modelContext.insert(newCategory)
        newCategoryName = ""
    }
    
    private func deleteCategory(at offsets: IndexSet) {
        for offset in offsets {
            let category = categories[offset]
            modelContext.delete(category)
        }
    }
    
    private func deleteSubcategory(from category: Category, at offsets: IndexSet) {
    }
}
