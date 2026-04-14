import Foundation
import Logging

enum DataLoaderError: Error {
    case noDataInFile(file: String)
    case jsonSerializationFailed
}

struct DataLoader {
    let logger: Logger

    init(logger: Logger) {
        self.logger = logger
    }

    func productsMap() -> [Any] {
        extractArray(key: "products", from: "products")
    }

    func ordersMap() -> [Data] {
        extractArrayData(key: "orders", from: "orders")
    }

    func shopData() -> Data {
        loadData(from: "shop") ?? Data()
    }

    func ordersData() -> Data {
        loadData(from: "orders") ?? Data()
    }

    func cartScenario<T: Decodable>(_ size: String, as type: T.Type = T.self) -> T? {
        guard let scenarios: [String: T] = decode(from: "cart_scenarios", as: [String: T].self)
        else {
            return nil
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
        extractFields("settings_json", fromArray: "products", in: "products")
    }

    func orderSettingsData() -> [Data] {
        extractFields("settings_json", fromArray: "orders", in: "orders")
    }

    func orderProductsData() -> [Data] {
        extractFields("products_json", fromArray: "orders", in: "orders")
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
        guard let data = FileManager.default.contents(atPath: "../data/\(file).json") else {
            logger.error("No data found in file: \(file).json")
            return nil
        }
        return data
    }

    private func decode<T: Decodable>(from file: String, as type: T.Type = T.self) -> T? {
        guard let raw = loadData(from: file) else { return nil }

        do {
            return try createDecoder().decode(type, from: raw)
        } catch {
            logger.error("Failed to decode \(file).json into \(String(describing: type)): \(error)")
            return nil
        }
    }
}

// DataLoader is only used in a read-only context without mutable state
// So we can flag it as sendable without actually meeting the requirements
// extension DataLoader: @unchecked Sendable {}
