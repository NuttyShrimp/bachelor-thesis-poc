struct CartScenario: Decodable {
    let itemCount: Int
    let items: [CartItem]
}

struct CartItem: Decodable, Sendable {
    let quantity: Int
    let unitPrice: Double
    let vatRate: Int
    let options: [CartOption]
}

struct CartOption: Decodable, Sendable {
    let price: Double
    let vatRate: Int
}

struct VatGroup: Sendable {
    let rate: Int
    var base: Double
    var vat: Double
}

struct VatResult: Sendable {
    let subtotal: Double
    let vatTotal: Double
    let total: Double
    let vatBreakdown: [VatGroup]
}
