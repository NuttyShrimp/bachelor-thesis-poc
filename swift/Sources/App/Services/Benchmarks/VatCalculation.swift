import Foundation
import Logging

struct VatCalculation: BenchmarkOperation {
    let iterations = 100
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
        var resultMap = [String: ScenarioResult]()
        let scenarioNames = ["smallCart", "mediumCart", "largeCart", "xlCart"]

        for scenario in scenarioNames {
            guard let cart = dataLoader.cartScenario(scenario, as: CartScenario.self) else {
                logger.error("Failed to load cart scenarios")
                return resultMap
            }
            resultMap[scenario] = benchmark(scenario: scenario, cart: cart)
        }

        return resultMap
    }

    private func benchmark(scenario: String, cart: CartScenario) -> ScenarioResult {
        let products = cart.items
        let itemCount = cart.itemCount

        _ = calculateForOrder(products: products)

        var times: [Double] = []
        let memoryUsageStart = reportMemory()
        let startTime = Int(Date.now.timeIntervalSince1970)

        for _ in 0..<iterations {
            let startTime = Date()
            _ = calculateForOrder(products: products)
            let stopTime = Date()
            let elapsedTime = stopTime.timeIntervalSince(startTime) * 1000
            times.append(elapsedTime)
        }

        let endTime = Int(Date.now.timeIntervalSince1970)
        let memoryUsageEnd = reportMemory()

        return ScenarioResult.create(
            for: "vat_calculation_\(scenario)",
            orderCount: itemCount,
            iterations: iterations,
            times: times,
            memoryUsage: memoryUsageEnd - memoryUsageStart,
            startTime: startTime,
            endTime: endTime
        )
    }

    private func calculateForOrder(products: [CartItem]) -> VatResult {
        var vatByRate = [Int: VatGroup]()
        var subtotal = 0.0
        var vatTotal = 0.0

        for product in products {
            let itemSubtotal = Double(product.quantity) * product.unitPrice
            let itemVat = itemSubtotal * (Double(product.vatRate) / 100)

            var productVatGroup =
                vatByRate[product.vatRate] ?? VatGroup(rate: product.vatRate, base: 0, vat: 0)
            productVatGroup.base += itemSubtotal
            productVatGroup.vat += itemVat
            vatByRate[product.vatRate] = productVatGroup

            subtotal += itemSubtotal
            vatTotal += itemVat

            for option in product.options {
                let optionSubtotal = Double(product.quantity) * option.price
                let optionVat = optionSubtotal * (Double(option.vatRate) / 100)

                var optionVatGroup =
                    vatByRate[option.vatRate] ?? VatGroup(rate: option.vatRate, base: 0, vat: 0)
                optionVatGroup.base += optionSubtotal
                optionVatGroup.vat += optionVat
                vatByRate[option.vatRate] = optionVatGroup

                subtotal += optionSubtotal
                vatTotal += optionVat
            }
        }

        return VatResult(
            subtotal: round2(subtotal),
            vatTotal: round2(vatTotal),
            total: round2(subtotal + vatTotal),
            vatBreakdown: Array(vatByRate.values)
        )
    }

    private func round2(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}
