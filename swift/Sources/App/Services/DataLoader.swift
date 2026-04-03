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
}

// DataLoader is only used in a read-only context without mutable state
// So we can flag it as sendable without actually meeting the requirements
extension DataLoader: @unchecked Sendable {}
