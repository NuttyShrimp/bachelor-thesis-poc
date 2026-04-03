struct CartScenario: Decodable {
    let itemCount: Int
    let items: [CartItem]
}

struct CartItem: Decodable, Sendable {
    let productId: Int
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

struct CartTotal: Sendable {
    var items: [CartTotalItem]
    var itemCount: Int
    var subtotal: Double
    var discountPercent: Int
    var discountAmount: Double
    var vatTotal: Double
    var total: Double
}

struct CartTotalItem: Sendable {
    var productId: Int
    var quantity: Int
    var unitPrice: Double
    var optionsPrice: Double
    var optionCount: Int
    var unitTotal: Double
    var totalExclVat: Double
    var vatRate: Int
    var vatAmount: Double
    var totalInclVat: Double
}
