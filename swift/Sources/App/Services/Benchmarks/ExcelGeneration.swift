import Foundation
import Logging
import libxlsxwriter
import xlsxwriter

private struct AggregatedRowKey: Hashable {
    let date: String
    let category: String
    let product: String
    let optionsKey: String
}

private struct ExcelRow {
    let date: String
    let category: String
    let product: String
    let options: String
    var quantity: Int
}

struct ExcelGeneration: BenchmarkOperation {
    let iterations = 10
    let dataLoader: DataLoader
    let logger: Logger

    init(dataLoader: DataLoader, logger: Logger) {
        self.dataLoader = dataLoader
        self.logger = logger
    }

    func description() -> BenchmarkOperationDescription {
        return BenchmarkOperationDescription(
            name: "excel_generation",
            complexity: "O(d*c*p*o)",
            scenarios: []
        )
    }

    func run() -> [String: ScenarioResult] {
        return [
            "excel_generation": benchmark()
        ]
    }

    private func benchmark() -> ScenarioResult {
        let rawData = dataLoader.ordersData()
        if rawData.isEmpty {
            logger.error("Orders payload is empty, cannot run excel generation benchmark")
            return ScenarioResult.create(
                for: "excel_generation",
                orderCount: 0,
                iterations: iterations,
                times: [],
                memoryUsage: 0,
                startTime: 0,
                endTime: 0
            )
        }

        let payload: ExcelOrdersPayload
        do {
            let decoder = createDecoder()
            payload = try decoder.decode(ExcelOrdersPayload.self, from: rawData)
        } catch {
            logger.error("Failed to decode orders payload for excel benchmark: \(error)")
            return ScenarioResult.create(
                for: "excel_generation",
                orderCount: 0,
                iterations: iterations,
                times: [],
                memoryUsage: 0,
                startTime: 0,
                endTime: 0
            )
        }

        let outputDirectory = benchmarkOutputDirectory()

        if let warmupFile = try? generateProductionList(
            payload: payload,
            outputDirectory: outputDirectory
        ) {
            try? FileManager.default.removeItem(at: warmupFile)
        }

        var times: [Double] = []
        times.reserveCapacity(iterations)

        var totalGeneratedFileSize: Double = 0
        var generatedFileCount = 0

        let memoryUsageStart = reportMemory()
        let startTime = Int(Date.now.timeIntervalSince1970)

        for _ in 0..<iterations {
            let startTime = DispatchTime.now().uptimeNanoseconds

            do {
                let fileURL = try generateProductionList(
                    payload: payload,
                    outputDirectory: outputDirectory
                )

                let stopTime = DispatchTime.now().uptimeNanoseconds
                let elapsedTime = Double(stopTime - startTime) / 1_000_000
                times.append(elapsedTime)

                if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
                    let fileSize = attributes[.size] as? NSNumber
                {
                    totalGeneratedFileSize += fileSize.doubleValue
                    generatedFileCount += 1
                }

                try? FileManager.default.removeItem(at: fileURL)
            } catch {
                let stopTime = DispatchTime.now().uptimeNanoseconds
                let elapsedTime = Double(stopTime - startTime) / 1_000_000
                times.append(elapsedTime)
                logger.error("Failed to generate excel file in benchmark iteration: \(error)")
            }
        }

        let endTime = Int(Date.now.timeIntervalSince1970)
        let memoryUsageEnd = reportMemory()
        if generatedFileCount > 0 {
            let avgSizeKb = totalGeneratedFileSize / Double(generatedFileCount) / 1024
            logger.debug("Average generated xlsx file size: \(avgSizeKb) KB")
        }

        return ScenarioResult.create(
            for: "excel_generation",
            orderCount: payload.orders.count,
            iterations: iterations,
            times: times,
            memoryUsage: memoryUsageEnd - memoryUsageStart,
            startTime: startTime,
            endTime: endTime
        )
    }

    private func generateProductionList(payload: ExcelOrdersPayload, outputDirectory: URL) throws
        -> URL
    {
        let rows = buildRows(from: payload)
        let outputPath = uniqueOutputPath(in: outputDirectory)

        let workbook = Workbook(name: outputPath.path)
        defer { workbook.close() }

        let worksheet = workbook.addWorksheet(name: "Production List")

        let headerFormat =
            workbook
            .addFormat()
            .bold()
            .border(style: .thin)
            .background(color: Color(hex: 0x4472C4))
            .font(color: Color(hex: 0xFFFFFF))
            .align(horizontal: .center)
            .align(vertical: .center)

        let rowFormat =
            workbook
            .addFormat()
            .border(style: .thin)

        let alternateRowFormat =
            workbook
            .addFormat()
            .border(style: .thin)
            .background(color: Color(hex: 0xE8E8E8))

        let headers = ["Date", "Category", "Product", "Options", "Quantity", "Notes"]
        worksheet.write(headers, row: 0, format: headerFormat)

        var maxColumnLengths = headers.map { $0.utf8.count }

        var rowIndex = 1
        var logicalRowCount = 0
        for row in rows {
            let currentFormat = logicalRowCount % 2 == 1 ? alternateRowFormat : rowFormat

            worksheet.write(.string(row.date), [rowIndex, 0], format: currentFormat)
            worksheet.write(.string(row.category), [rowIndex, 1], format: currentFormat)
            worksheet.write(.string(row.product), [rowIndex, 2], format: currentFormat)
            worksheet.write(.string(row.options), [rowIndex, 3], format: currentFormat)
            worksheet.write(.number(Double(row.quantity)), [rowIndex, 4], format: currentFormat)
            worksheet.write(.string(""), [rowIndex, 5], format: currentFormat)

            let quantityText = String(row.quantity)

            maxColumnLengths[0] = max(maxColumnLengths[0], row.date.utf8.count)
            maxColumnLengths[1] = max(maxColumnLengths[1], row.category.utf8.count)
            maxColumnLengths[2] = max(maxColumnLengths[2], row.product.utf8.count)
            maxColumnLengths[3] = max(maxColumnLengths[3], row.options.utf8.count)
            maxColumnLengths[4] = max(maxColumnLengths[4], quantityText.utf8.count)

            rowIndex += 1
            logicalRowCount += 1
        }

        for column in 0..<maxColumnLengths.count {
            let width = min(max(Double(maxColumnLengths[column] + 2), 10), 60)
            worksheet.column([column, column], width: width)
        }

        freezeHeaderRow(worksheet)

        return outputPath
    }

    private func freezeHeaderRow(_ worksheet: Worksheet) {
        let sheetPtr = Mirror(reflecting: worksheet)
            .children
            .compactMap { $0.value as? UnsafeMutablePointer<lxw_worksheet> }
            .first

        guard let sheetPtr else {
            logger.warning("Unable to apply freeze pane to worksheet")
            return
        }

        worksheet_freeze_panes(sheetPtr, 1, 0)
    }

    private func buildRows(from payload: ExcelOrdersPayload) -> [ExcelRow] {
        let fallbackDate = DateFormatter.excelBenchmarkDate.string(from: Date())

        var productsByOrderId: [Int: [ExcelOrderProduct]] = [:]
        productsByOrderId.reserveCapacity(payload.orders.count)
        for product in payload.orderProducts {
            productsByOrderId[product.orderId, default: []].append(product)
        }

        var optionNamesByOrderProductId: [Int: [String]] = [:]
        optionNamesByOrderProductId.reserveCapacity(payload.orderProductOptions.count)
        for option in payload.orderProductOptions {
            optionNamesByOrderProductId[option.orderProductId, default: []].append(
                option.name ?? "")
        }

        var optionStringByOrderProductId: [Int: String] = [:]
        optionStringByOrderProductId.reserveCapacity(optionNamesByOrderProductId.count)
        for (orderProductId, optionNames) in optionNamesByOrderProductId {
            optionStringByOrderProductId[orderProductId] = optionNames.joined(separator: ", ")
        }

        var rows: [ExcelRow] = []
        rows.reserveCapacity(payload.orderProducts.count)

        var rowIndexByKey: [AggregatedRowKey: Int] = [:]
        rowIndexByKey.reserveCapacity(payload.orderProducts.count)

        for order in payload.orders {
            let date = normalizedDate(order.createdAt, fallbackDate: fallbackDate)
            guard let orderProducts = productsByOrderId[order.id] else {
                continue
            }

            for product in orderProducts {
                let category = product.category ?? "Uncategorized"
                let productName = product.name ?? "Unknown Product"
                let optionString = optionStringByOrderProductId[product.id] ?? ""
                let optionsKey = optionString.isEmpty ? "no_options" : optionString

                let rowKey = AggregatedRowKey(
                    date: date,
                    category: category,
                    product: productName,
                    optionsKey: optionsKey
                )

                let quantity = product.quantity ?? 1
                if let rowIndex = rowIndexByKey[rowKey] {
                    rows[rowIndex].quantity += quantity
                    continue
                }

                rowIndexByKey[rowKey] = rows.count
                rows.append(
                    ExcelRow(
                        date: date,
                        category: category,
                        product: productName,
                        options: optionString.isEmpty ? "-" : optionString,
                        quantity: quantity
                    )
                )
            }
        }

        rows.sort(by: { $0.date.compare($1.date) == .orderedAscending })

        return rows
    }

    private func benchmarkOutputDirectory() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("bap-benchmarks", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func uniqueOutputPath(in directory: URL) -> URL {
        let timestamp = DispatchTime.now().uptimeNanoseconds
        return directory.appendingPathComponent("production_list_\(timestamp).xlsx")
    }

    private func normalizedDate(_ createdAt: String?, fallbackDate: String) -> String {
        guard let createdAt else {
            return fallbackDate
        }
        return String(createdAt.prefix(10))
    }
}

extension DateFormatter {
    fileprivate static let excelBenchmarkDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
