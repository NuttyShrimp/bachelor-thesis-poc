struct FullOrder: Codable {
    let productsJson: [OrderProduct]
    let settingsJson: OrderSettings

    enum CodingKeys: String, CodingKey {
        case productsJson = "products_json"
        case settingsJson = "settings_json"
    }
}

struct OrderProduct: Codable {
    let vat: OrderProductVatData?
    let gram: Int?
    let shop: OrderProductShopData?
    let amount: Int?
    let comment: String?
    let options: [OrderProductOption]?
    let persons: Int?
    let product: OrderProductData?
    let category: OrderProductCategory?
    let amountFree: Int?
    let productPrice: OrderProductPrice?
    let discountPrices: OrderProductCalculatedPrices?
    let calculatedPrices: OrderProductCalculatedPrices?

    enum CodingKeys: String, CodingKey {
        case vat
        case gram
        case shop
        case amount
        case comment
        case options
        case persons
        case product
        case category
        case amountFree = "amount_free"
        case productPrice = "product_price"
        case discountPrices = "discount_prices"
        case calculatedPrices = "calculated_prices"
    }
}

struct OrderProductVatData: Codable {
    let rate: Int?
    let id: Int?
}

struct OrderProductShopData: Codable {
    let id: Int?
}

struct OrderProductOption: Codable {
    let amount: Int?
    let product: OrderProductData?
    let productPrice: OrderProductPrice?

    enum CodingKeys: String, CodingKey {
        case amount
        case product
        case productPrice = "product_price"
    }
}

struct OrderProductData: Codable {
    let id: Int?
    let plu: String?
    let ppp: Float?
    let vat: Float?
    let code: String?
    let name: String?
    let price: Float?
    let minMax: OrderProductMinMax?
    let usePpp: Bool?
    let category: OrderProductCategory?
    let warranty: OrderProductWarranty?
    let priceType: Int?
    let targetPrice: Double?
    let onlyOnIsop: Int?
    let weightBased: Bool?
    let nameTranslated: String?
    let temperatureType: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case plu
        case ppp
        case vat
        case code
        case name
        case price
        case minMax = "min_max"
        case usePpp = "use_ppp"
        case category
        case warranty
        case priceType = "price_type"
        case targetPrice = "target_price"
        case onlyOnIsop = "only_on_isop"
        case weightBased = "weight_based"
        case nameTranslated = "name_translated"
        case temperatureType = "temperature_type"
    }
}

struct OrderProductMinMax: Codable {
    let stock: OrderProductMinMaxStock?
    let amount: OrderProductMinMaxAmount?
    let weight: OrderProductMinMaxWeight?
    let persons: OrderProductMinMaxPersons?
}

struct OrderProductMinMaxStock: Codable {
    let amount: Int?
}

struct OrderProductMinMaxAmount: Codable {
    let max: Int?
    let min: Int?
    let suggested: Int?
}

struct OrderProductMinMaxWeight: Codable {
    let max: Int?
    let min: Int?
    let suggested: Int?
}

struct OrderProductMinMaxPersons: Codable {
    let max: Int?
    let min: Int?
    let suggested: Int?
}

struct OrderProductWarranty: Codable {
    let type: Int?
    let price: Double?
}

struct OrderProductCategory: Codable {
    let id: Int?
    let name: String?
    let nameTranslated: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case nameTranslated = "name_translated"
    }
}

struct OrderProductPrice: Codable {
    let id: Int?
    let name: String?
    let price: Double?
    let warranty: OrderProductWarranty?
    let translations: [String: String]?
}

struct OrderProductCalculatedPrices: Codable {
    let price: Double?
    let unitPrice: Double?

    enum CodingKeys: String, CodingKey {
        case price
        case unitPrice = "unit_price"
    }
}

struct OrderSettings: Codable {
    let user: OrderSettingsUser?
    let deliveryAddress: OrderSettingsAddress?
    let invoiceAddress: OrderSettingsAddress?
    let costs: OrderSettingsCosts?
    let event: OrderSettingsEvent?
    let latch: OrderSettingsLatch?
    let piggy: OrderSettingsPiggy?
    let backup: OrderSettingsBackup?
    let stripe: OrderSettingsStripe?
    let payu: OrderSettingsPayu?
    let sibs: OrderSettingsSibs?
    let adyen: OrderSettingsAdyen?
    let urls: OrderSettingsUrls?
    let adelya: OrderSettingsAdelya?
    let edenred: OrderSettingsEdenred?
    let monizze: OrderSettingsMonizze?
    let parcify: OrderSettingsParcify?
    let payconiq: OrderSettingsPayconiq?
    let joynBadge: OrderSettingsJoynBadge?
    let extraInfo: OrderSettingsExtraInfo?
    let statistics: OrderSettingsStatistics?
    let warranty: OrderSettingsWarranty?
    let xerxes: OrderSettingsXerxes?
    let webpay: OrderSettingsWebpay?
}

struct OrderSettingsUser: Codable {
    let email: String?
    let tinNr: String?
    let lastname: String?
    let firstname: String?
    let telephone: String?
    let userId: Int?

    enum CodingKeys: String, CodingKey {
        case email
        case tinNr = "tin_nr"
        case lastname
        case firstname
        case telephone
        case userId = "user_id"
    }
}

struct OrderSettingsAddress: Codable {
    let street: String?
    let nr: String?
    let zipcode: String?
    let city: String?
    let country: String?
    let enable: Bool?
}

struct OrderSettingsCosts: Codable {
    let sms: Double?
}

struct OrderSettingsEvent: Codable {
    let orderNr: Int?

    enum CodingKeys: String, CodingKey {
        case orderNr = "order_nr"
    }
}

struct OrderSettingsLatch: Codable {
    let notificationMethod: String?

    enum CodingKeys: String, CodingKey {
        case notificationMethod = "notification_method"
    }
}

struct OrderSettingsPiggy: Codable {
    let qr: OrderSettingsPiggyQr?
    let sent: Bool?
    let cardNumber: String?

    enum CodingKeys: String, CodingKey {
        case qr
        case sent
        case cardNumber = "card_number"
    }
}

struct OrderSettingsPiggyQr: Codable {
    let id: Int?
    let url: String?
    let hash: String?
}

struct OrderSettingsBackup: Codable {
    let shopId: Int?
    let shopName: String?

    enum CodingKeys: String, CodingKey {
        case shopId = "shop_id"
        case shopName = "shop_name"
    }
}

struct OrderSettingsStripe: Codable {
    let paymentIntentId: String?

    enum CodingKeys: String, CodingKey {
        case paymentIntentId = "payment_intent_id"
    }
}

struct OrderSettingsPayu: Codable {
    let void: OrderSettingsPayuVoid?
    let brazil: OrderSettingsPayuBrazil?
    let authToken: String?

    enum CodingKeys: String, CodingKey {
        case void
        case brazil
        case authToken = "auth_token"
    }
}

struct OrderSettingsPayuVoid: Codable {
    let lastStatus: String?

    enum CodingKeys: String, CodingKey {
        case lastStatus = "last_status"
    }
}

struct OrderSettingsPayuBrazil: Codable {
    let sessionId: String?

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
    }
}

struct OrderSettingsSibs: Codable {
    let formContext: String?
    let purchaseRequestSent: Bool?
    let transactionSignature: String?

    enum CodingKeys: String, CodingKey {
        case formContext = "form_context"
        case purchaseRequestSent = "purchase_request_sent"
        case transactionSignature = "transaction_signature"
    }
}

struct OrderSettingsAdyen: Codable {
    let link: OrderSettingsAdyenLink?
    let paymentMethod: String?

    enum CodingKeys: String, CodingKey {
        case link
        case paymentMethod = "payment_method"
    }
}

struct OrderSettingsAdyenLink: Codable {
    let id: String?
}

struct OrderSettingsUrls: Codable {
    let failUrl: String?
    let successUrl: String?

    enum CodingKeys: String, CodingKey {
        case failUrl = "fail_url"
        case successUrl = "success_url"
    }
}

struct OrderSettingsAdelya: Codable {
    let card: String?
    let sent: Bool?
}

struct OrderSettingsEdenred: Codable {
    let authorizationId: String?

    enum CodingKeys: String, CodingKey {
        case authorizationId = "authorization_id"
    }
}

struct OrderSettingsMonizze: Codable {
    let transactionId: String?

    enum CodingKeys: String, CodingKey {
        case transactionId = "transaction_id"
    }
}

struct OrderSettingsParcify: Codable {
    let orderId: String?

    enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
    }
}

struct OrderSettingsPayconiq: Codable {
    let paymentId: String?

    enum CodingKeys: String, CodingKey {
        case paymentId = "payment_id"
    }
}

struct OrderSettingsJoynBadge: Codable {
    let points: Int?
    let token: String?
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case points
        case token
        case imageUrl = "image_url"
    }
}

struct OrderSettingsExtraInfo: Codable {
    let tableNumber: OrderSettingsExtraInfoTableNumber?
    let note: String?

    enum CodingKeys: String, CodingKey {
        case tableNumber = "table_number"
        case note
    }
}

struct OrderSettingsExtraInfoTableNumber: Codable {
    let color: String?
    let number: String?
}

struct OrderSettingsStatistics: Codable {
    let appSpace: String?
    let userAgent: String?
    let deviceInfo: String?

    enum CodingKeys: String, CodingKey {
        case appSpace = "app_space"
        case userAgent = "user_agent"
        case deviceInfo = "device_info"
    }
}

struct OrderSettingsWarranty: Codable {
    let bankAccount: String?

    enum CodingKeys: String, CodingKey {
        case bankAccount = "bank_account"
    }
}

struct OrderSettingsXerxes: Codable {
    let transactionId: String?

    enum CodingKeys: String, CodingKey {
        case transactionId = "transaction_id"
    }
}

struct OrderSettingsWebpay: Codable {
    let token: String?
}

// TODO: Should be renamed as its also used in the pdf tests
struct ExcelOrdersPayload: Codable {
    let orders: [ExcelOrder]
    let orderProducts: [ExcelOrderProduct]
    let orderProductOptions: [ExcelOrderProductOption]

    enum CodingKeys: String, CodingKey {
        case orders
        case orderProducts = "order_products"
        case orderProductOptions = "order_product_options"
    }
}

struct ExcelOrder: Codable, Sendable {
    let id: Int
    let createdAt: String?
    var products: [ExcelOrderProduct] = []

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
    }
}

struct ExcelOrderProduct: Codable, Sendable {
    let id: Int
    let orderId: Int
    let name: String?
    let category: String?
    var quantity: Int = 1
    var unitPrice: Double = 0
    var vatRate: Int = 21
    var options: [ExcelOrderProductOption] = []

    var total: Double {
        return Double(quantity) * unitPrice
    }
    var vatTotal: Double {
        return total * (Double(vatRate) / 100.0)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case orderId = "order_id"
        case name
        case category
        case quantity
        case unitPrice = "unit_price"
        case vatRate = "vat_rate"
    }
}

struct ExcelOrderProductOption: Codable, Sendable {
    let orderProductId: Int
    let name: String?

    enum CodingKeys: String, CodingKey {
        case orderProductId = "order_product_id"
        case name
    }
}
