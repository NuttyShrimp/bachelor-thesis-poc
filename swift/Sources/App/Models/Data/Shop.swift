import Foundation

struct Shop: Codable {
    let id: Int
    let name: String
    let slug: String
    let categories: [ShopCategory]
    let meta: [String: Int]
    let transformedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case slug
        case categories
        case meta
        case transformedAt = "transformed_at"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        slug = name.slugify()
        categories = try container.decode([ShopCategory].self, forKey: .categories)
        transformedAt = Date.now
        meta = [
            "category_count": categories.count,
            "product_count": categories.reduce(0) { $0 + $1.productCount },
        ]
    }
}

struct ShopCategory: Codable {
    let id: Int
    let name: String
    // Derived from name
    let slug: String
    // Derived from products
    let productCount: Int
    let products: [ShopProduct]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case products
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        slug = name.slugify()
        products = try container.decode([ShopProduct].self, forKey: .products)
        productCount = products.count
    }
}

struct ShopProduct: Codable {
    let id: Int
    let name: String
    let slug: String
    let description: String
    let price: Double
    let vatRate: Int
    let pricing: ShopProductPricing
    let availability: ShopProductAvailability

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case price
        case vatRate = "vat_rate"
        case slug
        case pricing
        case availability
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        slug = name.slugify()
        description = try container.decode(String.self, forKey: .description)
        price = try container.decode(Double.self, forKey: .price)
        vatRate = try container.decode(Int.self, forKey: .vatRate)
        availability = ShopProductAvailability()
        pricing = ShopProductPricing(price: price, vatRate: vatRate)
    }

}

struct ShopProductPricing: Codable {
    let priceExclVat: Double
    let priceInclVat: Double
    let vatRate: Int
    let vatAmount: Double
    let currency = "EUR"
    // Derived from priceInclVat
    let formatted: String

    init(price: Double, vatRate: Int) {
        priceInclVat = round(price * (1 + Double(vatRate) / 100)) / 100
        priceExclVat = round(price) / 100
        self.vatRate = vatRate
        vatAmount = round(priceInclVat - priceExclVat) / 100
        formatted = priceInclVat.formatted(.currency(code: "EUR"))
    }

}

struct ShopProductAvailability: Codable {
    let inStock = true
    let quantity = Int.random(in: 0...100)
    let status = "available"
}
