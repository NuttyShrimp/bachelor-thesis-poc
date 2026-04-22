import Foundation
import Logging
import ZIPFoundation

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
            scenarios: []
        )
    }

    func run() -> [String: ScenarioResult] {
        return [
            "single": benchmarkSingle(),
            "zip": benchmarkZip(),
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
                for: "pdf_generation_single",
                orderCount: 0,
                iterations: iterations,
                times: [],
                memoryUsage: 0,
                startTime: 0,
                endTime: 0
            )
        }

        var order = getFullOrder(payload: payload, for: 0)

        var times: [Double] = []
        let memoryUsageStart = reportMemory()
        let startTime = Int(Date.now.timeIntervalSince1970)

        for _ in 0..<iterations {
            do {
                let start = Date()
                let pdf = try renderInvoiceHtml(order: order)
                FileManager.default.createFile(atPath: "/tmp/swift-invoice.pdf", contents: pdf)
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

    func benchmarkZip() -> ScenarioResult {
        let orders = dataLoader.ordersData()
        let payload: ExcelOrdersPayload
        do {
            let decoder = createDecoder()
            payload = try decoder.decode(ExcelOrdersPayload.self, from: orders)
        } catch {
            logger.error("Failed to decode orders payload for excel benchmark: \(error)")
            return ScenarioResult.create(
                for: "pdf_generation_zip",
                orderCount: 0,
                iterations: iterations,
                times: [],
                memoryUsage: 0,
                startTime: 0,
                endTime: 0
            )
        }

        var times: [Double] = []
        let memoryUsageStart = reportMemory()
        let startTime = Int(Date.now.timeIntervalSince1970)

        for _ in 0..<10 {
            do {
                let start = Date()

                let url = try generateInvoiceZip(payload: payload)
                logger.debug("\(url)")

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
            for: "pdf_generation_zip",
            orderCount: 100,
            iterations: iterations,
            times: times,
            memoryUsage: memoryUsageEnd - memoryUsageStart,
            startTime: startTime,
            endTime: endTime
        )
    }

    func generateInvoiceZip(payload: ExcelOrdersPayload, limit: Int = 50) throws -> String {
        let fileManager = FileManager()
        var archiveURL = fileManager.temporaryDirectory
        archiveURL.appendPathComponent("bap")
        archiveURL.appendPathComponent("invoices_\(Int.random(in: 1000...9999)).zip")
        let archive = try Archive(url: archiveURL, accessMode: .create)

        for i in 0..<limit {
            let order = getFullOrder(payload: payload, for: i)
            let invoice = try renderInvoiceHtml(order: order)

            try archive.addEntry(
                with: "invoice_\(order.id).pdf", type: .file,
                uncompressedSize: Int64(invoice.count),
                // bufferSize: 4,
                provider: { (position, size) -> Data in
                    return invoice.subdata(in: Data.Index(position)..<Int(position) + size)
                })
        }

        return archiveURL.absoluteString
    }

    private func getFullOrder(payload: ExcelOrdersPayload, for index: Int) -> ExcelOrder {
        var order = payload.orders[index]

        order.products = payload.orderProducts.filter { $0.orderId == order.id }
        for i in order.products.indices {
            order.products[i].options = payload.orderProductOptions.filter {
                $0.orderProductId == order.products[i].id
            }
        }

        return order
    }

    func renderInvoiceHtml(order: ExcelOrder) throws -> Data {
        var itemsHtml = ""

        order.products.forEach { product in
            itemsHtml += """
                    <tr>
                        <td>\(product.name ?? "Product")<br><small style="color: #666;">\(product.options.map{$0.name ?? "Option"}.joined(separator: ","))</small></td>
                        <td style="text-align: center;">\(product.quantity)</td>
                        <td style="text-align: right;">€\(String(format: "%.2f", product.unitPrice))</td>
                        <td style="text-align: center;">\(String(format: "%.2f", product.vatRate))</td>
                        <td style="text-align: right;">€\(String(format: "%.2f", product.total))</td>
                    </tr> 
                """
        }

        let content = """
                <!DOCTYPE html>
                <html>
                <head>
                    <meta charset="utf-8">
                    <title>Invoice #\(order.id)</title>
                    <style>
                        * { margin: 0; padding: 0; box-sizing: border-box; }
                        body {
                            font-family: 'DejaVu Sans', Arial, sans-serif;
                            font-size: 11px;
                            line-height: 1.4;
                            color: #333;
                            padding: 40px;
                        }
                        .header {
                            border-bottom: 2px solid #4472C4;
                            padding-bottom: 20px;
                            margin-bottom: 30px;
                        }
                        .header h1 {
                            color: #4472C4;
                            font-size: 28px;
                            margin-bottom: 5px;
                        }
                        .invoice-info {
                            display: flex;
                            justify-content: space-between;
                            margin-bottom: 30px;
                        }
                        .invoice-info div {
                            width: 48%;
                        }
                        .invoice-info h3 {
                            color: #4472C4;
                            margin-bottom: 10px;
                            font-size: 14px;
                        }
                        table {
                            width: 100%;
                            border-collapse: collapse;
                            margin: 20px 0;
                        }
                        th {
                            background-color: #4472C4;
                            color: white;
                            padding: 12px 8px;
                            text-align: left;
                            font-weight: bold;
                        }
                        td {
                            border-bottom: 1px solid #ddd;
                            padding: 10px 8px;
                            vertical-align: top;
                        }
                        tr:nth-child(even) {
                            background-color: #f8f9fa;
                        }
                        .totals {
                            margin-top: 30px;
                            text-align: right;
                        }
                        .totals table {
                            width: 300px;
                            margin-left: auto;
                        }
                        .totals td {
                            padding: 8px;
                            border: none;
                        }
                        .totals .label {
                            text-align: right;
                            color: #666;
                        }
                        .totals .value {
                            text-align: right;
                            font-weight: bold;
                        }
                        .totals .grand-total {
                            font-size: 16px;
                            color: #4472C4;
                            border-top: 2px solid #4472C4;
                        }
                        .footer {
                            position: fixed;
                            bottom: 40px;
                            left: 40px;
                            right: 40px;
                            text-align: center;
                            color: #666;
                            font-size: 10px;
                            border-top: 1px solid #ddd;
                            padding-top: 15px;
                        }
                    </style>
                </head>
                <body>
                    <div class="header">
                        <h1>INVOICE</h1>
                        <p>Invoice Number: <strong>#\(order.id)</strong></p>
                        <p>Date: \(order.createdAt ?? Date().formatted(.dateTime))</p>
                    </div>

                    <table>
                        <thead>
                            <tr>
                                <th style="width: 40%;">Product</th>
                                <th style="width: 10%; text-align: center;">Qty</th>
                                <th style="width: 15%; text-align: right;">Unit Price</th>
                                <th style="width: 10%; text-align: center;">VAT</th>
                                <th style="width: 15%; text-align: right;">Total</th>
                            </tr>
                        </thead>
                        <tbody>
                            \(itemsHtml)
                        </tbody>
                    </table>

                    <div class="totals">
                        <table>
                            <tr>
                                <td class="label">Subtotal:</td>
                                <td class="value">€\(String(format: "%.3f", order.products.reduce(0) { $0 + $1.total}))</td>
                            </tr>
                            <tr>
                                <td class="label">VAT:</td>
                                <td class="value">€\(String(format: "%.3f",order.products.reduce(0, { $0 + $1.vatTotal})))</td>
                            </tr>
                            <tr class="grand-total">
                                <td class="label">Total:</td>
                                <td class="value">€\(String(format: "%.3f",order.products.reduce(0, { $0 + $1.total + $1.vatTotal})))</td>
                            </tr>
                        </table>
                    </div>

                    <div class="footer">
                        <p>Thank you for your business!</p>
                        <p>This is a computer-generated invoice for benchmark testing purposes.</p>
                    </div>
                </body>
                </html>
            """

        let helper = PdfHelper(content: content)

        return try helper.render()
    }
}
