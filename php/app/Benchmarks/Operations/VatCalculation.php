<?php

namespace App\Benchmarks\Operations;

use App\Benchmarks\DataLoader;

/**
 * VAT CALCULATION BENCHMARK
 *
 * This operation calculates VAT for orders with multiple items and options.
 * This is one of the most CPU-intensive pure computation tasks in the system.
 *
 * ALGORITHM:
 * 1. Loop through all order items
 * 2. For each item, calculate base VAT (quantity * unit_price * vat_rate)
 * 3. Loop through item options and add their VAT
 * 4. Group VAT amounts by rate (6%, 12%, 21%)
 * 5. Calculate totals per rate and grand total
 *
 * SWIFT IMPLEMENTATION NOTES:
 * ===========================
 * - Use structs for OrderItem, Option (value types = no heap allocation)
 * - Use Dictionary<Int, VatGroup> for VAT grouping
 * - Consider using reduce() instead of manual loops
 * - Use Decimal type for money calculations (avoid floating point issues)
 *
 * Example Swift struct:
 * ```swift
 * struct OrderItem {
 *     let productId: Int
 *     let quantity: Int
 *     let unitPrice: Decimal
 *     let vatRate: Int
 *     let options: [ItemOption]
 * }
 *
 * struct VatGroup {
 *     let rate: Int
 *     var base: Decimal = 0
 *     var vat: Decimal = 0
 * }
 *
 * func calculateVat(for order: Order) -> VatResult {
 *     var vatByRate: [Int: VatGroup] = [:]
 *     var subtotal: Decimal = 0
 *     var vatTotal: Decimal = 0
 *
 *     for item in order.products {
 *         let itemSubtotal = Decimal(item.quantity) * item.unitPrice
 *         let itemVat = itemSubtotal * (Decimal(item.vatRate) / 100)
 *
 *         vatByRate[item.vatRate, default: VatGroup(rate: item.vatRate)].base += itemSubtotal
 *         vatByRate[item.vatRate]!.vat += itemVat
 *
 *         subtotal += itemSubtotal
 *         vatTotal += itemVat
 *
 *         // Process options...
 *     }
 *
 *     return VatResult(subtotal: subtotal, vatTotal: vatTotal, breakdown: Array(vatByRate.values))
 * }
 * ```
 *
 * COMPLEXITY: O(n * m) where n = items, m = options per item
 */
class VatCalculation
{
    /**
     * Calculate VAT for a single order
     *
     * @param array $order Order with 'products' array containing items with options
     * @return array VAT breakdown with subtotal, vat_total, total, and breakdown by rate
     */
    public static function calculateForOrder(array $order): array
    {
        $vatByRate = [];
        $subtotal = 0;
        $vatTotal = 0;

        // Loop through order products
        foreach ($order['products'] as $product) {
            $itemSubtotal = $product['quantity'] * $product['unit_price'];
            $itemVatRate = $product['vat_rate'];
            $itemVat = $itemSubtotal * ($itemVatRate / 100);

            // Add to VAT grouping
            if (!isset($vatByRate[$itemVatRate])) {
                $vatByRate[$itemVatRate] = [
                    'rate' => $itemVatRate,
                    'base' => 0,
                    'vat' => 0,
                ];
            }

            $vatByRate[$itemVatRate]['base'] += $itemSubtotal;
            $vatByRate[$itemVatRate]['vat'] += $itemVat;

            $subtotal += $itemSubtotal;
            $vatTotal += $itemVat;

            // Process options (nested loop - this is the expensive part)
            foreach ($product['options'] ?? [] as $option) {
                $optionSubtotal = $product['quantity'] * $option['price'];
                $optionVatRate = $option['vat_rate'];
                $optionVat = $optionSubtotal * ($optionVatRate / 100);

                if (!isset($vatByRate[$optionVatRate])) {
                    $vatByRate[$optionVatRate] = [
                        'rate' => $optionVatRate,
                        'base' => 0,
                        'vat' => 0,
                    ];
                }

                $vatByRate[$optionVatRate]['base'] += $optionSubtotal;
                $vatByRate[$optionVatRate]['vat'] += $optionVat;

                $subtotal += $optionSubtotal;
                $vatTotal += $optionVat;
            }
        }

        return [
            'subtotal' => round($subtotal, 2),
            'vat_total' => round($vatTotal, 2),
            'total' => round($subtotal + $vatTotal, 2),
            'vat_breakdown' => array_values($vatByRate),
        ];
    }

    /**
     * Batch calculate VAT for multiple orders
     *
     * SWIFT NOTE: This is a good candidate for parallel processing
     * using DispatchQueue.concurrentPerform or async/await with TaskGroup
     *
     * ```swift
     * func calculateForOrders(_ orders: [Order]) async -> [VatResult] {
     *     await withTaskGroup(of: VatResult.self) { group in
     *         for order in orders {
     *             group.addTask { calculateVat(for: order) }
     *         }
     *         return await group.reduce(into: []) { $0.append($1) }
     *     }
     * }
     * ```
     */
    public static function calculateForOrders(array $orders): array
    {
        $results = [];

        foreach ($orders as $order) {
            $results[] = self::calculateForOrder($order);
        }

        return $results;
    }

    /**
     * Run benchmark with cart scenarios
     *
     * @param string $scenario One of: small_cart, medium_cart, large_cart, xl_cart
     * @param int $iterations Number of times to run the calculation
     * @return array Benchmark results with timing statistics
     */
    public static function benchmark(string $scenario = 'large_cart', int $iterations = 100): array
    {
        $cart = DataLoader::cartScenario($scenario);

        // Warm up (ensure code paths are hot)
        self::calculateForOrder(['products' => $cart['items']]);

        $times = [];
        $memoryStart = memory_get_usage(true);
        $totalStart = hrtime(true);

        for ($i = 0; $i < $iterations; $i++) {
            $start = hrtime(true);

            $result = self::calculateForOrder(['products' => $cart['items']]);

            $end = hrtime(true);
            $times[] = ($end - $start) / 1_000_000; // Convert nanoseconds to ms
        }

        $memoryEnd = memory_get_usage(true);
        $totalEnd = hrtime(true);

        return [
            'operation' => 'vat_calculation',
            'scenario' => $scenario,
            'item_count' => $cart['item_count'],
            'iterations' => $iterations,
            'start_time_ms' => $totalStart,
            'end_time_ms' => $totalEnd,
            'avg_time_ms' => round(array_sum($times) / count($times), 3),
            'min_time_ms' => round(min($times), 3),
            'max_time_ms' => round(max($times), 3),
            'std_dev_ms' => round(self::standardDeviation($times), 3),
            'p25_time_ms' => round($times[(int)(count($times) * 0.25)], 3),
            'p50_time_ms' => round($times[(int)(count($times) * 0.50)], 3),
            'p75_time_ms' => round($times[(int)(count($times) * 0.75)], 3),
            'p95_time_ms' => round(self::percentile($times, 95), 3),
            'p99_time_ms' => round(self::percentile($times, 99), 3),
            'memory_used_mb' => round(($memoryEnd - $memoryStart) / 1024 / 1024, 2),
            'total_time_ms' => round(array_sum($times), 3),
        ];
    }

    /**
     * Calculate percentile from array of values
     */
    private static function percentile(array $data, int $percentile): float
    {
        sort($data);
        $index = ceil(($percentile / 100) * count($data)) - 1;
        return $data[$index] ?? 0;
    }

    /**
     * Calculate standard deviation
     */
    private static function standardDeviation(array $data): float
    {
        $count = count($data);
        if ($count === 0) return 0;

        $mean = array_sum($data) / $count;
        $squaredDiffs = array_map(fn($x) => pow($x - $mean, 2), $data);

        return sqrt(array_sum($squaredDiffs) / $count);
    }
}
