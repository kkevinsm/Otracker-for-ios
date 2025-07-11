import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var name: String
    
    @Relationship(deleteRule: .cascade, inverse: \Subcategory.category)
    var subcategories: [Subcategory] = []
    
    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction] = []
    
    @Relationship(deleteRule: .cascade, inverse: \Budget.category)
    var budgets: [Budget] = []
    
    init(name: String) {
        self.name = name
    }
}

@Model
final class Subcategory {
    @Attribute(.unique) var name: String
    
    var category: Category?
    
    @Relationship(deleteRule: .nullify, inverse: \Transaction.subcategory)
    var transactions: [Transaction] = []
    
    init(name: String) {
        self.name = name
    }
}
