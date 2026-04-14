struct FullOrder: Decodable {
    let productsJson: [OrderProduct]
    let settingsJson: OrderSettings
}

struct OrderProduct: Decodable {
    let vat: OrderProductVatData?
    let gram: Int?
    let shop: OrderProductShopData?
    let amount: Int?
    let comment: String?
    let options: [OrderProductOption]
    let persons: Int?
    let product: OrderProductData?
    let category: OrderProductCategory?
    let amountFree: Int?
    let productPrice: OrderProductPrice?
    let discountPrices: OrderProductCalculatedPrices?
    let calculatedPrices: OrderProductCalculatedPrices?
}

struct OrderProductVatData: Decodable {
    let rate: Int?
    let id: Int?
}

struct OrderProductShopData: Decodable {
    let id: Int?
}

struct OrderProductOption: Decodable {
    let amount: Int?
    let product: OrderProductData?
    let productPrice: OrderProductPrice?
}

struct OrderProductData: Decodable {
    let id: Int?
    let plu: String?
    let ppp: Double?
    let vat: Int?
    let code: String?
    let name: String?
    let price: Double?
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
}

struct OrderProductMinMax: Decodable {
    let stock: OrderProductMinMaxStock?
    let amount: OrderProductMinMaxAmount?
    let weight: OrderProductMinMaxWeight?
    let persons: OrderProductMinMaxPersons?
}

struct OrderProductMinMaxStock: Decodable {
    let amount: Int?
}

struct OrderProductMinMaxAmount: Decodable {
    let max: Int?
    let min: Int?
    let suggested: Int?
}

struct OrderProductMinMaxWeight: Decodable {
    let max: Int?
    let min: Int?
    let suggested: Int?
}

struct OrderProductMinMaxPersons: Decodable {
    let max: Int?
    let min: Int?
    let suggested: Int?
}

struct OrderProductWarranty: Decodable {
    let type: Int?
    let price: Double?
}

struct OrderProductCategory: Decodable {
    let id: Int?
    let name: String?
    let nameTranslated: String?
}

struct OrderProductPrice: Decodable {
    let id: Int?
    let name: String?
    let price: Double?
    let warranty: OrderProductWarranty?
    let translations: [String: String]?
}

struct OrderProductCalculatedPrices: Decodable {
    let price: Double?
    let unitPrice: Double?
}

struct OrderSettings: Decodable {
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

struct OrderSettingsUser: Decodable {
    let email: String?
    let tinNr: String?
    let lastname: String?
    let firstname: String?
    let telephone: String?
    let userId: Int?
}

struct OrderSettingsAddress: Decodable {
    let street: String?
    let nr: String?
    let zipcode: String?
    let city: String?
    let country: String?
    let enable: Bool?
}

struct OrderSettingsCosts: Decodable {
    let sms: Double?
}

struct OrderSettingsEvent: Decodable {
    let orderNr: Int?
}

struct OrderSettingsLatch: Decodable {
    let notificationMethod: String?
}

struct OrderSettingsPiggy: Decodable {
    let qr: OrderSettingsPiggyQr?
    let sent: Bool?
    let cardNumber: String?
}

struct OrderSettingsPiggyQr: Decodable {
    let id: Int?
    let url: String?
    let hash: String?
}

struct OrderSettingsBackup: Decodable {
    let shopId: Int?
    let shopName: String?
}

struct OrderSettingsStripe: Decodable {
    let paymentIntentId: String?
}

struct OrderSettingsPayu: Decodable {
    let void: OrderSettingsPayuVoid?
    let brazil: OrderSettingsPayuBrazil?
    let authToken: String?
}

struct OrderSettingsPayuVoid: Decodable {
    let lastStatus: String?
}

struct OrderSettingsPayuBrazil: Decodable {
    let sessionId: String?
}

struct OrderSettingsSibs: Decodable {
    let formContext: String?
    let purchaseRequestSent: Bool?
    let transactionSignature: String?
}

struct OrderSettingsAdyen: Decodable {
    let link: OrderSettingsAdyenLink?
    let paymentMethod: String?
}

struct OrderSettingsAdyenLink: Decodable {
    let id: String?
}

struct OrderSettingsUrls: Decodable {
    let failUrl: String?
    let successUrl: String?
}

struct OrderSettingsAdelya: Decodable {
    let card: String?
    let sent: Bool?
}

struct OrderSettingsEdenred: Decodable {
    let authorizationId: String?
}

struct OrderSettingsMonizze: Decodable {
    let transactionId: String?
}

struct OrderSettingsParcify: Decodable {
    let orderId: String?
}

struct OrderSettingsPayconiq: Decodable {
    let paymentId: String?
}

struct OrderSettingsJoynBadge: Decodable {
    let points: Int?
    let token: String?
    let imageUrl: String?
}

struct OrderSettingsExtraInfo: Decodable {
    let tableNumber: OrderSettingsExtraInfoTableNumber?
    let note: String?
}

struct OrderSettingsExtraInfoTableNumber: Decodable {
    let color: String?
    let number: String?
}

struct OrderSettingsStatistics: Decodable {
    let appSpace: String?
    let userAgent: String?
    let deviceInfo: String?
}

struct OrderSettingsWarranty: Decodable {
    let bankAccount: String?
}

struct OrderSettingsXerxes: Decodable {
    let transactionId: String?
}

struct OrderSettingsWebpay: Decodable {
    let token: String?
}

struct ExcelOrdersPayload: Decodable {
    let orders: [ExcelOrder]
    let orderProducts: [ExcelOrderProduct]
    let orderProductOptions: [ExcelOrderProductOption]
}

struct ExcelOrder: Decodable {
    let id: Int
    let createdAt: String?
}

struct ExcelOrderProduct: Decodable {
    let id: Int
    let orderId: Int
    let name: String?
    let category: String?
    let quantity: Int?
}

struct ExcelOrderProductOption: Decodable {
    let orderProductId: Int
    let name: String?
}
