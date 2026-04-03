import Foundation
import Logging

struct CartCalculation: BenchmarkOperation {
    let iterations = 100
    let dataLoader: DataLoader
    let logger: Logger

    init(dataLoader: DataLoader, logger: Logger) {
        self.dataLoader = dataLoader
        self.logger = logger
    }

    func description() -> BenchmarkOperationDescription {
        return BenchmarkOperationDescription(
            name: "cart_calculation",
            complexity: "O(n*m)",
            scenarios: [
                "small_cart", "medium_cart", "large_cart", "xl_cart",
            ]
        )
    }

    func run() -> [String: ScenarioResult] {
        var resultMap = [String: ScenarioResult]()
        let scenarios = ["small_cart", "medium_cart", "large_cart", "xl_cart"]

        for scenario in scenarios {
            guard let result = benchmark(scenario: scenario) else {
                logger.error("Failed to run benchmark for: \(scenario)")
                continue
            }
            resultMap[scenario] = result
        }

        return resultMap
    }

    private func benchmark(scenario: String) -> ScenarioResult? {
        guard let cart: CartScenario = dataLoader.cartScenario(scenario, as: CartScenario.self)
        else {
            return nil
        }
        var results: [CartTotal] = []

        _ = calculateCartTotal(cart: cart, discount: 10)

        var times: [Double] = []
        let memoryUsageStart = reportMemory()

        for i in 0..<iterations {
            let startTime = Date()

            let result = calculateCartTotal(cart: cart, discount: i)
            results.append(result)

            let stopTime = Date()
            let elapsedTime = stopTime.timeIntervalSince(startTime) * 1000
            times.append(elapsedTime)
        }

        let memoryUsageEnd = reportMemory()

        return ScenarioResult.create(
            for: "vat_calculation_\(scenario)",
            orderCount: 0,
            iterations: iterations,
            times: times,
            memoryUsage: memoryUsageEnd - memoryUsageStart
        )

    }

    private func calculateCartTotal(cart: CartScenario, discount: Int? = nil) -> CartTotal {
        var items: [CartTotalItem] = []
        var subTotal = 0.0

        for item in cart.items {
            let result = calculateCartItem(for: item)
            items.append(result)
            subTotal += result.totalExclVat
        }

        var discountAmount = 0.0
        if let discount = discount {
            discountAmount = subTotal * (Double(discount) / 100.0)
            subTotal -= discountAmount
        }

        var vatTotal = 0.0
        let originalSubtotal = subTotal + discountAmount

        for item in items {
            let itemProportion = originalSubtotal > 0 ? (item.totalExclVat / originalSubtotal) : 0
            let adjustedBase = subTotal * itemProportion
            vatTotal += adjustedBase * (Double(item.vatRate) / 100.0)
        }

        return CartTotal(
            items: items,
            itemCount: items.count,
            subtotal: round(subTotal) / 100,
            discountPercent: discount ?? 0,
            discountAmount: round(discountAmount) / 100,
            vatTotal: round(vatTotal) / 100,
            total: round(subTotal + vatTotal) / 100
        )
    }

    private func calculateCartItem(for item: CartItem) -> CartTotalItem {
        let optionsPrice = item.options.reduce(0, { $0 + $1.price })
        let lineTotal = (item.unitPrice + optionsPrice) * Double(item.quantity)
        return CartTotalItem(
            productId: item.productId,
            quantity: item.quantity,
            unitPrice: round(item.unitPrice) / 100,
            optionsPrice: optionsPrice,
            optionCount: item.options.count,
            unitTotal: item.unitPrice + optionsPrice,
            totalExclVat: round(lineTotal) / 100,
            vatRate: item.vatRate,
            vatAmount: round(lineTotal * (Double(item.vatRate) / 100.0)) / 100,
            totalInclVat: round(lineTotal * (1 + (Double(item.vatRate) / 100.0))) / 100
        )
    }
}
