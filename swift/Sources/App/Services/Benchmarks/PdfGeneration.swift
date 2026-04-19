import Foundation
import Logging
import SwiftlyPDFKit

struct PdfGeneration: BenchmarkOperation {
    let iterations = 50
    let dataLoader: DataLoader
    let logger: Logger

    init(dataLoader: DataLoader, logger: Logger) {
        self.dataLoader = dataLoader
        self.logger = logger
    }

    func description() -> BenchmarkOperationDescription {
        return BenchmarkOperationDescription(
            name: "vat_calculation",
            complexity: "O(n*m)",
            scenarios: [
                "smallCart", "mediumCart", "largeCart", "xlCart",
            ]
        )
    }

    func run() -> [String: ScenarioResult] {
        return [
            "single": benchmarkSingle()
        ]
    }

    func benchmarkSingle() -> ScenarioResult {
        let orders = dataLoader.ordersData()
        let payload: ExcelOrdersPayload
        do {
            let decoder = createDecoder()
            payload = try decoder.decode(ExcelOrdersPayload.self, from: orders)
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

        var order = payload.orders[0]

        order.products = payload.orderProducts.filter { $0.orderId != order.id }
        for i in order.products.indices {
            order.products[i].options = payload.orderProductOptions.filter {
                $0.orderProductId == order.products[i].id
            }
        }

        var times: [Double] = []
        let memoryUsageStart = reportMemory()
        let startTime = Int(Date.now.timeIntervalSince1970)

        for _ in 0..<iterations {
            do {
                let start = Date()
                let _ = try renderInvoiceHtml(order: order)
                let end = Date()
                let elapsedTime = end.timeIntervalSince(start) * 1000
                times.append(elapsedTime)
                logger.debug("Iteration elapsed in \(elapsedTime)")
            } catch {
                logger.error("Failed to render invoice: \(error)")
            }
        }

        let endTime = Int(Date.now.timeIntervalSince1970)
        let memoryUsageEnd = reportMemory()
        return ScenarioResult.create(
            for: "pdf_generation_single",
            orderCount: 100,
            iterations: iterations,
            times: times,
            memoryUsage: memoryUsageEnd - memoryUsageStart,
            startTime: startTime,
            endTime: endTime
        )
    }

    func renderInvoiceHtml(order: ExcelOrder) throws -> Data {
        let pdf = PDF {
            Page(size: .a4, margins: 40) {
                Text("INVOICE")
                    .foregroundColor(.init(red: 68, green: 114, blue: 196))
                    .fontSize(28)
                Spacer(height: 5)
                Columns(spacing: 0) {
                    ColumnItem {
                        Text("Invoice Number: ")
                    }
                    ColumnItem {
                        Text("#\(order.id)").bold()
                    }
                }
                Text("Date: \(order.createdAt)")
                Spacer(height: 70)
                Table(
                    data: order.products.map {
                        var output = [String]()
                        output.append("\($0.name ?? "Product")")
                        output.append(String($0.quantity ?? 1))
                        output.append(String($0.unitPrice ?? 0))
                        output.append(String($0.vatRate ?? 21))
                        output.append(String($0.total))

                        return output
                    },
                    style: .init(
                        headerBackground: .init(red: 68, green: 114, blue: 196),
                        headerTextColor: .white, headerFontSize: 10, cellFontSize: 10,
                        rowHeight: 20, alternateRowColor: .init(red: 248, green: 249, blue: 250),
                        borderColor: PDFColor(white: 0.7),
                        borderWidth: 0.25, cellPadding: 4, cellBold: false)
                ) {
                    Column("Product")
                    Column("Qty", alignment: .center, headerAlignment: .center)
                    Column("Unit Price", alignment: .trailing, headerAlignment: .trailing)
                    Column("VAT", alignment: .center, headerAlignment: .center)
                    Column("Total", alignment: .trailing, headerAlignment: .trailing)
                }
                Spacer(height: 50)
                Columns(spacing: 0) {
                    ColumnItem {
                        Text("Subtotal:")
                        Text("VAT:")
                        Text("Total:")
                    }
                    ColumnItem {
                        Text("€\(order.products.reduce(0) { $0 + $1.total})")
                        Text("€\(order.products.reduce(0, { $0 + $1.vatTotal}))")
                        Text("€\(order.products.reduce(0, { $0 + $1.total + $1.vatTotal}))")
                    }
                }
            }
        }

        return try pdf.render()
    }
}
