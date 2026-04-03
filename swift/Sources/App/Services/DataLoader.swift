import Foundation
import Logging

enum DataLoaderError: Error {
    case NoDataInFile(file: String)
    case JSONSerializationFailed
}

class DataLoader {
    let decoder: JSONDecoder
    let logger: Logger

    init(logger: Logger) {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.logger = logger
    }

    func productsMap() -> [Any] {
        do {
            let data = try load(from: "products")
            if data["products"] == nil {
                throw DataLoaderError.NoDataInFile(file: "products")
            }
            return data["products"] as? [Any] ?? []
        } catch {
            logger.error("Failed to load products data: \(error)")
            return []
        }
    }

    func ordersMap() -> [Any] {
        do {
            let data = try load(from: "orders")
            if data["orders"] == nil {
                throw DataLoaderError.NoDataInFile(file: "orders")
            }
            return data["orders"] as? [Any] ?? []
        } catch {
            logger.error("Failed to load orders data: \(error)")
            return []
        }
    }

    func shopData() -> Data {
        do {
            return try loadData(from: "shop")
        } catch {
            logger.error("Failed to load shop data: \(error)")
            return Data()
        }
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

    private func load(from file: String) throws -> [String: Any] {
        let fileData = FileManager.default.contents(atPath: "../data/\(file).json")
        if fileData == nil {
            throw DataLoaderError.NoDataInFile(file: file)
        }
        guard
            let json = try JSONSerialization.jsonObject(with: fileData!, options: [])
                as? [String: Any]
        else {
            throw DataLoaderError.JSONSerializationFailed
        }
        return json
    }

    private func loadData(from file: String) throws -> Data {
        let fileData = FileManager.default.contents(atPath: "../data/\(file).json")
        if fileData == nil {
            throw DataLoaderError.NoDataInFile(file: file)
        }
        return fileData!
    }

    private func decode<T: Decodable>(from file: String, as type: T.Type = T.self) -> T? {
        do {
            let raw = try loadData(from: file)
            return try decoder.decode(type, from: raw)
        } catch {
            logger.error("Failed to decode \(file).json into \(String(describing: type)): \(error)")
            return nil
        }
    }

}

// DataLoader is only used in a read-only context without mutable state
// So we can flag it as sendable without actually meeting the requirements
extension DataLoader: @unchecked Sendable {}
