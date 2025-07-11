import Foundation
import SwiftData

@Model
final class Transaction {
    var transactionDescription: String
    var amount: Double
    var date: Date
    
    var category: Category?
    var subcategory: Subcategory?
    var sourceOfFund: SourceOfFund?
    
    init(description: String, amount: Double, date: Date, category: Category?, subcategory: Subcategory?, sourceOfFund: SourceOfFund?) {
        self.transactionDescription = description
        self.amount = amount
        self.date = date
        self.category = category
        self.subcategory = subcategory
        self.sourceOfFund = sourceOfFund
    }
}
