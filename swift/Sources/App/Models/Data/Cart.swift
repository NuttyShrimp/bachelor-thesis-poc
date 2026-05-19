import Foundation
import NewCodable

@JSONCodable
struct CartScenario {
    @CodingKey("item_count")
    let itemCount: Int
    let items: [CartItem]
}

@JSONCodable
struct CartItem: Sendable {
    @CodingKey("product_id")
    let productId: Int
    let quantity: Int
    @CodingKey("unit_price")
    let unitPrice: Double
    @CodingKey("vat_rate")
    let vatRate: Int
    let options: [CartOption]
}

@JSONCodable
struct CartOption: Sendable {
    let price: Double
    @CodingKey("vat_rate")
    let vatRate: Int
}

@JSONCodable
struct VatGroup: Sendable {
    let rate: Int
    var base: Double
    var vat: Double
}

@JSONCodable
struct VatResult: Sendable {
    let subtotal: Double
    let vatTotal: Double
    let total: Double
    let vatBreakdown: [VatGroup]
}

@JSONCodable
struct CartTotal: Sendable {
    var items: [CartTotalItem]
    var itemCount: Int
    var subtotal: Double
    var discountPercent: Int
    var discountAmount: Double
    var vatTotal: Double
    var total: Double
}

@JSONCodable
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
