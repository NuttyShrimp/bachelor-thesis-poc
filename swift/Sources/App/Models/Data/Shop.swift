import Foundation
import NewCodable

@JSONEncodable
struct Shop {
    let id: Int
    let name: String
    let slug: String
    let categories: [ShopCategory]
    let meta: [String: Int]
    @CodingKey("transformed_at")
    let transformedAt: Date

    // init(from decoder: any Decoder) throws {
    //     let container = try decoder.container(keyedBy: CodingKeys.self)
    //
    //     id = try container.decode(Int.self, forKey: .id)
    //     name = try container.decode(String.self, forKey: .name)
    //     slug = name.slugify()
    //     categories = try container.decode([ShopCategory].self, forKey: .categories)
    //     transformedAt = Date.now
    //     meta = [
    //         "category_count": categories.count,
    //         "product_count": categories.reduce(0) { $0 + $1.productCount },
    //     ]
    // }
}

extension Shop: JSONDecodable {
    static func decode(from decoder: inout some JSONDecoderProtocol & ~Escapable) throws(CodingError
        .Decoding)
        -> Shop
    {
        try decoder.decodeStruct { structDecoder throws(CodingError.Decoding) in
            let requiredFields = 1
            var requiredFieldsSeen = 0

            var id: Int?
            var name: String?
            var categories: [ShopCategory]

            var intermediateStorage = structDecoder.prepareIntermediateValueStorage()

            try structDecoder.decodeEachKeyAndValue {
                key, valueDecoder throws(CodingError.Decoding) in
                switch key {
                case "id":
                    id = try valueDecoder.decode(Int.self)
                    requiredFieldsSeen += 1
                case "name":
                    name = try valueDecoder.decode(String.self)
                    requiredFieldsSeen += 1
                default:
                    intermediateStorage.append(
                        (key: key, value: try valueDecoder.decodeJSONPrimitive()))
                }
                return requiredFieldsSeen == requiredFields && intermediateStorage.isEmpty
            }
            guard let id else {
                throw CodingError.dataCorrupted(debugDescription: "Missing 'id' field")
            }
            guard let name else {
                throw CodingError.dataCorrupted(debugDescription: "Missing 'name' field")
            }

            if requiredFields == requiredFieldsSeen, intermediateStorage.isEmpty {
                categories = try structDecoder.withWrappingDecoder {
                    wrappingDecoder throws(CodingError.Decoding) in
                    try wrappingDecoder.decode([ShopCategory].self)
                }
            } else {
                var decoder = JSONPrimitiveDecoder(
                    keysAndValues: intermediateStorage, codingPath: structDecoder.codingPath)
                categories = try decoder.decode([ShopCategory].self)
            }

            return Shop(
                id: id,
                name: name,
                slug: name.slugify(),
                categories: categories,
                meta: [
                    "category_count": categories.count,
                    "product_count": categories.reduce(0) { $0 + $1.productCount },
                ],
                transformedAt: Date.now,
            )
        }
    }
}

@JSONEncodable
struct ShopCategory {
    let id: Int
    let name: String
    // Derived from name
    let slug: String
    // Derived from products
    let productCount: Int
    let products: [ShopProduct]

    // init(from decoder: any Decoder) throws {
    //     let container = try decoder.container(keyedBy: CodingKeys.self)
    //
    //     id = try container.decode(Int.self, forKey: .id)
    //     name = try container.decode(String.self, forKey: .name)
    //     slug = name.slugify()
    //     products = try container.decode([ShopProduct].self, forKey: .products)
    //     productCount = products.count
    // }
}

extension ShopCategory: JSONDecodable {
    static func decode(from decoder: inout some JSONDecoderProtocol & ~Escapable) throws(CodingError
        .Decoding)
        -> ShopCategory
    {
        try decoder.decodeStruct { structDecoder throws(CodingError.Decoding) in
            let requiredFields = 1
            var requiredFieldsSeen = 0

            var id: Int?
            var name: String?
            var products: [ShopProduct]

            var intermediateStorage = structDecoder.prepareIntermediateValueStorage()

            try structDecoder.decodeEachKeyAndValue {
                key, valueDecoder throws(CodingError.Decoding) in
                switch key {
                case "id":
                    id = try valueDecoder.decode(Int.self)
                    requiredFieldsSeen += 1
                case "name":
                    name = try valueDecoder.decode(String.self)
                    requiredFieldsSeen += 1
                default:
                    intermediateStorage.append(
                        (key: key, value: try valueDecoder.decodeJSONPrimitive()))
                }
                return requiredFieldsSeen == requiredFields && intermediateStorage.isEmpty
            }
            guard let id else {
                throw CodingError.dataCorrupted(debugDescription: "Missing 'id' field")
            }
            guard let name else {
                throw CodingError.dataCorrupted(debugDescription: "Missing 'name' field")
            }

            if requiredFields == requiredFieldsSeen, intermediateStorage.isEmpty {
                products = try structDecoder.withWrappingDecoder {
                    wrappingDecoder throws(CodingError.Decoding) in
                    try wrappingDecoder.decode([ShopProduct].self)
                }
            } else {
                var decoder = JSONPrimitiveDecoder(
                    keysAndValues: intermediateStorage, codingPath: structDecoder.codingPath)
                products = try decoder.decode([ShopProduct].self)
            }

            return ShopCategory(
                id: id,
                name: name,
                slug: name.slugify(),
                productCount: products.count,
                products: products,
            )
        }
    }
}

@JSONEncodable
struct ShopProduct {
    let id: Int
    let name: String
    let slug: String
    let description: String
    let price: Double
    @CodingKey("vat_rate")
    let vatRate: Int
    let pricing: ShopProductPricing
    let availability: ShopProductAvailability

    // init(from decoder: any Decoder) throws {
    //     let container = try decoder.container(keyedBy: CodingKeys.self)
    //
    //     id = try container.decode(Int.self, forKey: .id)
    //     name = try container.decode(String.self, forKey: .name)
    //     slug = name.slugify()
    //     description = try container.decode(String.self, forKey: .description)
    //     price = try container.decode(Double.self, forKey: .price)
    //     vatRate = try container.decode(Int.self, forKey: .vatRate)
    //     availability = ShopProductAvailability()
    //     pricing = ShopProductPricing(price: price, vatRate: vatRate)
    // }

}

extension ShopProduct: JSONDecodable {
    static func decode(from decoder: inout some JSONDecoderProtocol & ~Escapable) throws(CodingError
        .Decoding)
        -> ShopProduct
    {
        try decoder.decodeStruct { structDecoder throws(CodingError.Decoding) in
            var id: Int?
            var name: String?
            var description: String?
            var price: Double?
            var vatRate: Int?

            try structDecoder.decodeEachKeyAndValue {
                key, valueDecoder throws(CodingError.Decoding) in
                switch key {
                case "id":
                    id = try valueDecoder.decode(Int.self)
                case "name":
                    name = try valueDecoder.decode(String.self)
                case "description":
                    description = try valueDecoder.decode(String.self)
                case "price":
                    price = try valueDecoder.decode(Double.self)
                case "vat_rate":
                    vatRate = try valueDecoder.decode(Int.self)
                default:
                    break  // Skip unknown keys
                }
                return false
            }
            guard let id else {
                throw CodingError.dataCorrupted(debugDescription: "Missing 'id' field")
            }
            guard let name else {
                throw CodingError.dataCorrupted(debugDescription: "Missing 'name' field")
            }
            guard let description else {
                throw CodingError.dataCorrupted(debugDescription: "Missing 'description' field")
            }
            guard let price else {
                throw CodingError.dataCorrupted(debugDescription: "Missing 'price' field")
            }
            guard let vatRate else {
                throw CodingError.dataCorrupted(debugDescription: "Missing 'vatRate' field")
            }

            return ShopProduct(
                id: id,
                name: name,
                slug: name.slugify(),
                description: description,
                price: price,
                vatRate: vatRate,
                pricing: ShopProductPricing(price: price, vatRate: vatRate),
                availability: ShopProductAvailability()
            )
        }
    }
}

@JSONEncodable
struct ShopProductPricing {
    let priceExclVat: Double
    let priceInclVat: Double
    let vatRate: Int
    let vatAmount: Double
    let currency: String = "EUR"
    let formatted: String

    init(price: Double, vatRate: Int) {
        priceInclVat = round(price * (1 + Double(vatRate) / 100)) / 100
        priceExclVat = round(price) / 100
        self.vatRate = vatRate
        vatAmount = round(priceInclVat - priceExclVat) / 100
        formatted = priceInclVat.formatted(.currency(code: "EUR"))
    }

}

@JSONEncodable
struct ShopProductAvailability {
    let inStock: Bool = true
    let quantity: Int = Int.random(in: 0...100)
    let status: String = "available"
}
