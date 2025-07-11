import Foundation
import SwiftData

@Model
final class SourceOfFund {
    @Attribute(.unique) var name: String
    
    @Relationship(deleteRule: .nullify, inverse: \Transaction.sourceOfFund)
    var transactions: [Transaction] = []
    
    init(name: String) {
        self.name = name
    }
}
