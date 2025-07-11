import SwiftUI
import SwiftData

struct AddBudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query(sort: \Category.name) private var categories: [Category]

    @State private var selectedCategory: Category?
    @State private var amount: Double = 0.0

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("add_budget_section_header")) {
                    Picker("add_budget_picker_label", selection: $selectedCategory) {
                        Text("add_budget_picker_placeholder").tag(Category?.none)
                        ForEach(categories) { category in
                            Text(category.name).tag(category as Category?)
                        }
                    }
                    
                    TextField("add_budget_amount_placeholder", value: $amount, format: .currency(code: "IDR"))
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("add_budget_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("add_budget_cancel_button") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("add_budget_save_button") { saveBudget() }
                        .disabled(selectedCategory == nil || amount == 0)
                }
            }
        }
    }
    
    private func saveBudget() {
        guard let category = selectedCategory else { return }
        
        let newBudget = Budget(amount: amount, date: .now, category: category)
        modelContext.insert(newBudget)
        
        try? modelContext.save()
        dismiss()
    }
}
