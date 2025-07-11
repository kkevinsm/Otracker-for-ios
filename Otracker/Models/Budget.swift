import Foundation
import SwiftData

@Model
final class Budget {
    var amount: Double
    var date: Date
    
    var category: Category?
    
    init(amount: Double, date: Date, category: Category?) {
        self.amount = amount
        self.date = date
        self.category = category
    }
}
