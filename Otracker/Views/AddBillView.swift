import SwiftUI

struct AddBillView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var amount: Double = 0.0
    @State private var paymentDay: Int = 1
    
    let daysInMonth: [Int] = Array(1...31)

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("add_bill_section_header")) {
                    TextField("add_bill_name_placeholder", text: $name)
                    TextField("add_bill_amount_placeholder", value: $amount, format: .currency(code: "IDR"))
                        .keyboardType(.decimalPad)
                    
                    Picker("add_bill_due_date_label", selection: $paymentDay) {
                                            ForEach(daysInMonth, id: \.self) { day in
                                                Text("\(day)")
                                                    .tag(day)
                        }
                    }
                }
            }
            .navigationTitle("add_bill_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("add_bill_cancel_button") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("add_bill_save_button") { saveBill() }
                        .disabled(name.isEmpty || amount == 0)
                }
            }
        }
    }
    
    private func saveBill() {
        let newBill = RecurringPayment(name: name, amount: amount, paymentDay: paymentDay)
        modelContext.insert(newBill)
        dismiss()
    }
}
//
//  AddBillView.swift
//  Otracker
//
//  Created by Kev on 09/07/25.
//

