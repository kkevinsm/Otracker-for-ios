import SwiftUI
import SwiftData

struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Budget.date, order: .reverse) private var budgets: [Budget]
    @Query private var transactions: [Transaction] // Tidak perlu diurutkan di sini
    
    @State private var showingAddBudgetSheet = false

    private var currentMonthBudgets: [Budget] {
        let calendar = Calendar.current
        return budgets.filter { budget in
            calendar.isDate(budget.date, equalTo: Date(), toGranularity: .month)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if currentMonthBudgets.isEmpty {
                    ContentUnavailableView(
                        "budget_view_empty_title",
                        systemImage: "target",
                        description: Text("budget_view_empty_description")
                    )
                } else {
                    ForEach(currentMonthBudgets.sorted(by: {
                        $0.category?.name ?? "" < $1.category?.name ?? ""
                    })) { budget in
                        BudgetRowView(budget: budget, allTransactions: transactions)
                    }
                    .onDelete(perform: deleteBudgets)
                }
            }
            .navigationTitle("budget_view_title")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddBudgetSheet.toggle() } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAddBudgetSheet) {
                AddBudgetView()
            }
        }
    }
    
    private func deleteBudgets(offsets: IndexSet) {
        let sortedBudgets = currentMonthBudgets.sorted(by: { $0.category?.name ?? "" < $1.category?.name ?? "" })
        withAnimation {
            for index in offsets {
                let budgetToDelete = sortedBudgets[index]
                modelContext.delete(budgetToDelete)
            }
        }
    }
}


struct BudgetRowView: View {
    let budget: Budget
    let allTransactions: [Transaction]
    
    private var budgetInfo: (spent: Double, progress: Double, color: Color) {
        guard let budgetCategory = budget.category else {
            return (0, 0, .gray)
        }
        
        let calendar = Calendar.current
        
        let relevantTransactions = allTransactions.filter { transaction in
            return transaction.category == budgetCategory &&
                   calendar.isDate(transaction.date, equalTo: budget.date, toGranularity: .month)
        }
        
        let spentAmount = relevantTransactions.reduce(0) { $0 + $1.amount }
        
        let progress = budget.amount > 0 ? spentAmount / budget.amount : 0
        
        let color: Color
        if progress > 1.0 { color = .red }
        else if progress > 0.75 { color = .orange }
        else { color = .green }
        
        return (spentAmount, progress, color)
    }
    
    
    private func formattedCurrency(_ amount: Double) -> String {
            return amount.formatted(.currency(code: "IDR"))
        }
    
    var body: some View {
        let info = budgetInfo 
        let remainingAmount = budget.amount - info.spent
        
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(budget.category?.name ?? "budget_row_no_category").font(.headline)
                Spacer()
                Text(budget.amount, format: .currency(code: "IDR"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            ProgressView(value: info.progress > 1.0 ? 1.0 : info.progress)
                .tint(info.color)
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            HStack {
                Text(String(format: NSLocalizedString("budget_row_spent", comment: ""), formattedCurrency(info.spent)))
                                   .font(.caption)
                                   .foregroundStyle(info.color)
                               
                Spacer()
                               
                Text(String(format: NSLocalizedString("budget_row_remaining", comment: ""), formattedCurrency(remainingAmount)))
                                   .font(.caption)
                                   .foregroundStyle(remainingAmount < 0 ? .red : .secondary)            }
        }
        .padding(.vertical, 8)
    }
}
