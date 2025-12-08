import Foundation

struct IdentifiableDate: Identifiable {
    let date: Date
    var id: Date { date }
}
