import Foundation
import Logging
import NewCodable

enum DataLoaderError: Error {
    case noDataInFile(file: String)
    case jsonSerializationFailed
}

final class DataLoader: @unchecked Sendable {
    let logger: Logger

    private var isCacheEnabled: Bool = false
    private var memoryCache: [String: Any] = [:]
    private let lock = NSLock()

    init(logger: Logger) {
        self.logger = logger
    }

    func enableCache() {
        lock.lock()
        defer { lock.unlock() }
        isCacheEnabled = true
    }

    func disableCache() {
        lock.lock()
        defer { lock.unlock() }
        isCacheEnabled = false
        memoryCache.removeAll()
    }

    private func getCached<T>(key: String) -> T? {
        lock.lock()
        defer { lock.unlock() }
        guard isCacheEnabled else { return nil }
        return memoryCache[key] as? T
    }

    private func setCached(key: String, value: Any) {
        lock.lock()
        defer { lock.unlock() }
        if isCacheEnabled {
            memoryCache[key] = value
        }
    }

    func preloadData() {
        enableCache()

        _ = productsMap()
        _ = ordersMap()
        _ = shopData()
        _ = ordersData()
        _ = productSettingsData()
        _ = orderSettingsData()
        _ = orderProductsData()

        _ = loadData(from: "cart_scenarios")
    }

    func productsMap() -> [Any] {
        if let cached: [Any] = getCached(key: "productsMap") { return cached }
        let result = extractArray(key: "products", from: "products")
        setCached(key: "productsMap", value: result)
        return result
    }

    func ordersMap() -> [Data] {
        if let cached: [Data] = getCached(key: "ordersMap") { return cached }
        let result = extractArrayData(key: "orders", from: "orders")
        setCached(key: "ordersMap", value: result)
        return result
    }

    func shopData() -> Data {
        if let cached: Data = getCached(key: "shopData") { return cached }
        let result = loadData(from: "shop") ?? Data()
        setCached(key: "shopData", value: result)
        return result
    }

    func ordersData() -> Data {
        if let cached: Data = getCached(key: "ordersData") { return cached }
        let result = loadData(from: "orders") ?? Data()
        setCached(key: "ordersData", value: result)
        return result
    }

    func cartScenario<T: JSONCodable>(_ size: String, as type: T.Type = T.self) -> T? {
        let cacheKey = "cartScenarios_\(String(describing: T.self))"
        let scenarios: [String: T]

        if let cached: [String: T] = getCached(key: cacheKey) {
            scenarios = cached
        } else {
            guard let decoded: [String: T] = decode(from: "cart_scenarios", as: [String: T].self)
            else { return nil }
            scenarios = decoded
            setCached(key: cacheKey, value: scenarios)
        }

        if let scenario = scenarios[size] {
            return scenario
        }

        logger.warning("Cart scenario \(size) not found, using medium_cart")

        if let fallback = scenarios["medium_cart"] {
            return fallback
        }

        logger.error("Fallback cart scenario medium_cart not found")
        return nil
    }

    func productSettingsData() -> [Data] {
        if let cached: [Data] = getCached(key: "productSettingsData") { return cached }
        let result = extractFields("settings_json", fromArray: "products", in: "products")
        setCached(key: "productSettingsData", value: result)
        return result
    }

    func orderSettingsData() -> [Data] {
        if let cached: [Data] = getCached(key: "orderSettingsData") { return cached }
        let result = extractFields("settings_json", fromArray: "orders", in: "orders")
        setCached(key: "orderSettingsData", value: result)
        return result
    }

    func orderProductsData() -> [Data] {
        if let cached: [Data] = getCached(key: "orderProductsData") { return cached }
        let result = extractFields("products_json", fromArray: "orders", in: "orders")
        setCached(key: "orderProductsData", value: result)
        return result
    }

    private func extractArray(key: String, from file: String) -> [Any] {
        guard let raw = loadData(from: file) else { return [] }

        do {
            guard
                let root = try JSONSerialization.jsonObject(with: raw) as? [String: Any],
                let array = root[key] as? [Any]
            else {
                throw DataLoaderError.jsonSerializationFailed
            }
            return array
        } catch {
            logger.error("Failed to extract '\(key)' array from \(file).json: \(error)")
            return []
        }
    }

    private func extractArrayData(key: String, from file: String) -> [Data] {
        guard let raw = loadData(from: file) else { return [] }

        do {
            guard
                let root = try JSONSerialization.jsonObject(with: raw) as? [String: Any],
                let array = root[key] as? [Any]
            else {
                throw DataLoaderError.jsonSerializationFailed
            }

            return try array.compactMap { try JSONSerialization.data(withJSONObject: $0) }
        } catch {
            logger.error("Failed to extract '\(key)' array from \(file).json: \(error)")
            return []
        }
    }

    private func extractFields(_ field: String, fromArray arrayKey: String, in file: String)
        -> [Data]
    {
        guard let raw = loadData(from: file) else { return [] }

        do {
            guard
                let root = try JSONSerialization.jsonObject(with: raw) as? [String: Any],
                let array = root[arrayKey] as? [[String: Any]]
            else {
                throw DataLoaderError.jsonSerializationFailed
            }

            return try array.compactMap { entry -> Data? in
                guard let value = entry[field] else { return nil }
                return try JSONSerialization.data(withJSONObject: value)
            }
        } catch {
            logger.error("Failed to extract '\(field)' from \(file).json[\(arrayKey)]: \(error)")
            return []
        }
    }

    private func loadData(from file: String) -> Data? {
        if let cached: Data = getCached(key: "raw_\(file)") {
            return cached
        }

        guard let data = try? Data(contentsOf: URL(filePath: "../data/\(file).json")) else {
            logger.error("No data found in file: \(file).json")
            return nil
        }

        setCached(key: "raw_\(file)", value: data)
        return data
    }

    private func decode<T: JSONCodable>(from file: String, as type: T.Type = T.self)
        -> T?
    {
        guard let raw = loadData(from: file) else { return nil }

        do {
            return try createDecoder().decode(type, from: raw.bytes)
        } catch {
            logger.error("Failed to decode \(file).json into \(String(describing: type)): \(error)")
            return nil
        }
    }
}
