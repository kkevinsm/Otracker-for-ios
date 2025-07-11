import Foundation
import SwiftData

@Model
final class RecurringPayment {
    var name: String
    var amount: Double
    var paymentDay: Int
    var lastPaidDate: Date?
    
    init(name: String, amount: Double, paymentDay: Int) {
        self.name = name
        self.amount = amount
        self.paymentDay = paymentDay
    }
    
    var isPaidForCurrentMonth: Bool {
        guard let lastPaidDate = lastPaidDate else { return false }
        return Calendar.current.isDate(lastPaidDate, equalTo: Date(), toGranularity: .month)
    }
}
