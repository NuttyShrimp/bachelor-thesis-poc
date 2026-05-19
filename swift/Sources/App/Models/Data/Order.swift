import NewCodable

@JSONDecodable
struct FullOrder {
    @CodingKey("products_json")
    let productsJson: [OrderProduct]
    @CodingKey("settings_json")
    let settingsJson: OrderSettings
}

@JSONDecodable
struct OrderProduct {
    let vat: OrderProductVatData?
    let gram: Int?
    let shop: OrderProductShopData?
    let amount: Int?
    let comment: String?
    let options: [OrderProductOption]?
    let persons: Int?
    let product: OrderProductData?
    let category: OrderProductCategory?
    @CodingKey("amount_free")
    let amountFree: Int?
    @CodingKey("product_price")
    let productPrice: OrderProductPrice?
    @CodingKey("discount_prices")
    let discountPrices: OrderProductCalculatedPrices?
    @CodingKey("calculated_prices")
    let calculatedPrices: OrderProductCalculatedPrices?
}

@JSONDecodable
struct OrderProductVatData {
    let rate: Int?
    let id: Int?
}

@JSONDecodable
struct OrderProductShopData {
    let id: Int?
}

@JSONDecodable
struct OrderProductOption {
    let amount: Int?
    let product: OrderProductData?
    @CodingKey("product_price")
    let productPrice: OrderProductPrice?
}

@JSONDecodable
struct OrderProductData {
    let id: Int?
    let plu: String?
    let ppp: Float?
    let vat: Float?
    let code: String?
    let name: String?
    let price: Float?
    @CodingKey("min_max")
    let minMax: OrderProductMinMax?
    @CodingKey("use_ppp")
    let usePpp: Bool?
    let category: OrderProductCategory?
    let warranty: OrderProductWarranty?
    @CodingKey("price_type")
    let priceType: Int?
    @CodingKey("target_price")
    let targetPrice: Double?
    @CodingKey("only_on_isop")
    let onlyOnIsop: Int?
    @CodingKey("weight_based")
    let weightBased: Bool?
    @CodingKey("name_translated")
    let nameTranslated: String?
    @CodingKey("temperature_type")
    let temperatureType: Int?
}

@JSONDecodable
struct OrderProductMinMax {
    let stock: OrderProductMinMaxStock?
    let amount: OrderProductMinMaxAmount?
    let weight: OrderProductMinMaxWeight?
    let persons: OrderProductMinMaxPersons?
}

@JSONDecodable
struct OrderProductMinMaxStock {
    let amount: Int?
}

@JSONDecodable
struct OrderProductMinMaxAmount {
    let max: Int?
    let min: Int?
    let suggested: Int?
}

@JSONDecodable
struct OrderProductMinMaxWeight {
    let max: Int?
    let min: Int?
    let suggested: Int?
}

@JSONDecodable
struct OrderProductMinMaxPersons {
    let max: Int?
    let min: Int?
    let suggested: Int?
}

@JSONDecodable
struct OrderProductWarranty {
    let type: Int?
    let price: Double?
}

@JSONDecodable
struct OrderProductCategory {
    let id: Int?
    let name: String?
    @CodingKey("name_translated")
    let nameTranslated: String?
}

@JSONDecodable
struct OrderProductPrice {
    let id: Int?
    let name: String?
    let price: Double?
    let warranty: OrderProductWarranty?
    let translations: [String: String]?
}

@JSONDecodable
struct OrderProductCalculatedPrices {
    let price: Double?
    @CodingKey("unit_price")
    let unitPrice: Double?
}

@JSONDecodable
struct OrderSettings {
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

@JSONDecodable
struct OrderSettingsUser {
    let email: String?
    @CodingKey("tin_nr")
    let tinNr: String?
    let lastname: String?
    let firstname: String?
    let telephone: String?
    @CodingKey("user_id")
    let userId: Int?
}

@JSONDecodable
struct OrderSettingsAddress {
    let street: String?
    let nr: String?
    let zipcode: String?
    let city: String?
    let country: String?
    let enable: Bool?
}

@JSONDecodable
struct OrderSettingsCosts {
    let sms: Double?
}

@JSONDecodable
struct OrderSettingsEvent {
    @CodingKey("order_nr")
    let orderNr: Int?
}

@JSONDecodable
struct OrderSettingsLatch {
    @CodingKey("notification_method")
    let notificationMethod: String?
}

@JSONDecodable
struct OrderSettingsPiggy {
    let qr: OrderSettingsPiggyQr?
    let sent: Bool?
    @CodingKey("card_number")
    let cardNumber: String?
}

@JSONDecodable
struct OrderSettingsPiggyQr {
    let id: Int?
    let url: String?
    let hash: String?
}

@JSONDecodable
struct OrderSettingsBackup {
    @CodingKey("shop_id")
    let shopId: Int?
    @CodingKey("shop_name")
    let shopName: String?
}

@JSONDecodable
struct OrderSettingsStripe {
    @CodingKey("payment_intent_id")
    let paymentIntentId: String?
}

@JSONDecodable
struct OrderSettingsPayu {
    let void: OrderSettingsPayuVoid?
    let brazil: OrderSettingsPayuBrazil?
    @CodingKey("auth_token")
    let authToken: String?
}

@JSONDecodable
struct OrderSettingsPayuVoid {
    @CodingKey("last_status")
    let lastStatus: String?
}

@JSONDecodable
struct OrderSettingsPayuBrazil {
    @CodingKey("session_id")
    let sessionId: String?
}

@JSONDecodable
struct OrderSettingsSibs {
    @CodingKey("form_context")
    let formContext: String?
    @CodingKey("purchase_request_sent")
    let purchaseRequestSent: Bool?
    @CodingKey("transaction_signature")
    let transactionSignature: String?
}

@JSONDecodable
struct OrderSettingsAdyen {
    let link: OrderSettingsAdyenLink?
    @CodingKey("payment_method")
    let paymentMethod: String?
}

@JSONDecodable
struct OrderSettingsAdyenLink {
    let id: String?
}

@JSONDecodable
struct OrderSettingsUrls {
    @CodingKey("fail_url")
    let failUrl: String?
    @CodingKey("success_url")
    let successUrl: String?
}

@JSONDecodable
struct OrderSettingsAdelya {
    let card: String?
    let sent: Bool?
}

@JSONDecodable
struct OrderSettingsEdenred {
    @CodingKey("authorization_id")
    let authorizationId: String?
}

@JSONDecodable
struct OrderSettingsMonizze {
    @CodingKey("transaction_id")
    let transactionId: String?
}

@JSONDecodable
struct OrderSettingsParcify {
    @CodingKey("order_id")
    let orderId: String?
}

@JSONDecodable
struct OrderSettingsPayconiq {
    @CodingKey("payment_id")
    let paymentId: String?
}

@JSONDecodable
struct OrderSettingsJoynBadge {
    let points: Int?
    let token: String?
    @CodingKey("image_url")
    let imageUrl: String?
}

@JSONDecodable
struct OrderSettingsExtraInfo {
    @CodingKey("table_number")
    let tableNumber: OrderSettingsExtraInfoTableNumber?
    let note: String?
}

@JSONDecodable
struct OrderSettingsExtraInfoTableNumber {
    let color: String?
    let number: String?
}

@JSONDecodable
struct OrderSettingsStatistics {
    @CodingKey("app_space")
    let appSpace: String?
    @CodingKey("user_agent")
    let userAgent: String?
    @CodingKey("device_info")
    let deviceInfo: String?
}

@JSONDecodable
struct OrderSettingsWarranty {
    @CodingKey("bank_account")
    let bankAccount: String?
}

@JSONDecodable
struct OrderSettingsXerxes {
    @CodingKey("transaction_id")
    let transactionId: String?
}

@JSONDecodable
struct OrderSettingsWebpay {
    let token: String?
}

// TODO: Should be renamed as its also used in the pdf tests

@JSONDecodable
struct ExcelOrdersPayload {
    let orders: [ExcelOrder]
    @CodingKey("order_products")
    let orderProducts: [ExcelOrderProduct]
    @CodingKey("order_product_options")
    let orderProductOptions: [ExcelOrderProductOption]
}

@JSONDecodable
struct ExcelOrder: Sendable {
    let id: Int
    @CodingKey("created_at")
    let createdAt: String?
    var products: [ExcelOrderProduct] = []
}

@JSONDecodable
struct ExcelOrderProduct: Sendable {
    let id: Int
    @CodingKey("order_id")
    let orderId: Int
    let name: String?
    let category: String?
    var quantity: Int = 1
    @CodingKey("unit_price")
    var unitPrice: Double = 0
    @CodingKey("vat_rate")
    var vatRate: Int = 21
    var options: [ExcelOrderProductOption] = []

    var total: Double {
        return Double(quantity) * unitPrice
    }
    var vatTotal: Double {
        return total * (Double(vatRate) / 100.0)
    }
}

@JSONDecodable
struct ExcelOrderProductOption: Sendable {
    @CodingKey("order_product_id")
    let orderProductId: Int
    let name: String?
}
