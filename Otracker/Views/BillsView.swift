import SwiftUI
import SwiftData

struct BillsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\RecurringPayment.paymentDay), SortDescriptor(\RecurringPayment.name)]) private var bills: [RecurringPayment]
    
    @State private var showingAddBillSheet = false

    var body: some View {
        NavigationStack {
            List {
                if bills.isEmpty {
                    ContentUnavailableView(
                        "bills_view_empty_title",
                        systemImage: "calendar.badge.plus",
                        description: Text("bills_view_empty_description")
                    )
                } else {
                    ForEach(bills) { bill in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(bill.name).fontWeight(.bold)
                                
                                Text(String(format: NSLocalizedString("bills_view_due_date_format", comment: ""), bill.paymentDay))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if bill.isPaidForCurrentMonth {
                                VStack {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                    Text("bills_view_status_paid").font(.caption).foregroundStyle(.green)
                                }
                            } else {
                                Button("bills_view_pay_button") { pay(bill: bill) }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.orange)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onDelete(perform: deleteBills)
                }
            }
            .navigationTitle("bills_view_title")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddBillSheet.toggle() } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAddBillSheet) {
                AddBillView()
            }
        }
    }
    
    private func pay(bill: RecurringPayment) {
        
        let categoryName = NSLocalizedString("bills_view_default_category", comment: "")
        let category: Category
        
        let fetchDescriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.name == categoryName })
        if let existingCategory = try? modelContext.fetch(fetchDescriptor).first {
            category = existingCategory
        } else {
            let newCategory = Category(name: categoryName)
            modelContext.insert(newCategory)
            category = newCategory
        }
        
        let sourceName = NSLocalizedString("bills_view_default_source", comment: "")
        let source: SourceOfFund
        
        let sourceFetchDescriptor = FetchDescriptor<SourceOfFund>(predicate: #Predicate { $0.name == sourceName })
        if let existingSource = try? modelContext.fetch(sourceFetchDescriptor).first {
            source = existingSource
        } else {
            let newSource = SourceOfFund(name: sourceName)
            modelContext.insert(newSource)
            source = newSource
        }
        
        let descriptionFormat = NSLocalizedString("bills_view_payment_description_format", comment: "")
        
        let newTransaction = Transaction(
            description: String(format: descriptionFormat, bill.name),
            amount: bill.amount,
            date: .now,
            category: category,
            subcategory: nil,
            sourceOfFund: source
        )
        modelContext.insert(newTransaction)
        
        bill.lastPaidDate = .now
        
        try? modelContext.save()
    }
    
    private func deleteBills(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let billToDelete = bills[index]
                modelContext.delete(billToDelete)
            }
        }
    }
}
