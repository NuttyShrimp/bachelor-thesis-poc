<?php

namespace App\Benchmarks\Operations;

use App\Benchmarks\DataLoader;

/**
 * CART CALCULATION BENCHMARK
 *
 * Calculates prices for a shopping cart with items, options, and discounts.
 * Simulates the CartCalculator from production.
 *
 * ALGORITHM:
 * 1. Calculate base price per item (quantity * unit_price)
 * 2. Add option prices per item
 * 3. Apply item-level discounts (if any)
 * 4. Calculate line subtotals
 * 5. Apply cart-level discounts
 * 6. Calculate VAT per line
 * 7. Calculate final total
 *
 * SWIFT IMPLEMENTATION NOTES:
 * ===========================
 * - Define CartItem, CartOption as structs (value types)
 * - Use computed properties for derived values (total, vatAmount)
 * - Use Decimal for money (never Float/Double for currency!)
 * - Swift's map/reduce are highly optimized
 *
 * Example Swift:
 * ```swift
 * struct CartItem {
 *     let productId: Int
 *     let quantity: Int
 *     let unitPrice: Decimal
 *     let vatRate: Int
 *     let options: [CartOption]
 *
 *     var optionsTotal: Decimal {
 *         options.reduce(0) { $0 + $1.price }
 *     }
 *
 *     var unitTotal: Decimal {
 *         unitPrice + optionsTotal
 *     }
 *
 *     var lineTotal: Decimal {
 *         unitTotal * Decimal(quantity)
 *     }
 *
 *     var vatAmount: Decimal {
 *         lineTotal * (Decimal(vatRate) / 100)
 *     }
 * }
 *
 * struct Cart {
 *     let items: [CartItem]
 *     let discountPercent: Decimal?
 *
 *     var subtotal: Decimal {
 *         items.reduce(0) { $0 + $1.lineTotal }
 *     }
 *
 *     var discountAmount: Decimal {
 *         guard let percent = discountPercent else { return 0 }
 *         return subtotal * (percent / 100)
 *     }
 *
 *     var vatTotal: Decimal {
 *         items.reduce(0) { $0 + $1.vatAmount }
 *     }
 *
 *     var total: Decimal {
 *         subtotal - discountAmount + vatTotal
 *     }
 * }
 * ```
 *
 * COMPLEXITY: O(n * m) where n = items, m = options per item
 */
class CartCalculation
{
    /**
     * Calculate cart totals
     *
     * @param array $cart Cart data with 'items' array
     * @param float|null $discountPercent Optional cart-level discount percentage
     * @return array Calculated cart with items and totals
     */
    public static function calculate(array $cart, ?float $discountPercent = null): array
    {
        $items = [];
        $subtotal = 0;

        foreach ($cart['items'] as $item) {
            $itemResult = self::calculateItem($item);
            $items[] = $itemResult;
            $subtotal += $itemResult['total_excl_vat'];
        }

        // Apply cart-level discount
        $discountAmount = 0;
        if ($discountPercent !== null && $discountPercent > 0) {
            $discountAmount = $subtotal * ($discountPercent / 100);
            $subtotal -= $discountAmount;
        }

        // Calculate VAT on discounted amounts (proportionally)
        $vatTotal = 0;
        $originalSubtotal = $subtotal + $discountAmount;

        foreach ($items as $item) {
            // Each item's VAT is reduced proportionally by the discount
            $itemProportion = $originalSubtotal > 0
                ? $item['total_excl_vat'] / $originalSubtotal
                : 0;
            $adjustedBase = $subtotal * $itemProportion;
            $vatTotal += $adjustedBase * ($item['vat_rate'] / 100);
        }

        return [
            'items' => $items,
            'item_count' => count($items),
            'subtotal' => round($subtotal, 2),
            'discount_percent' => $discountPercent ?? 0,
            'discount_amount' => round($discountAmount, 2),
            'vat_total' => round($vatTotal, 2),
            'total' => round($subtotal + $vatTotal, 2),
        ];
    }

    /**
     * Calculate single item price
     */
    private static function calculateItem(array $item): array
    {
        $basePrice = $item['unit_price'];
        $optionsPrice = 0;
        $optionCount = 0;

        // Calculate options total
        foreach ($item['options'] ?? [] as $option) {
            $optionsPrice += $option['price'];
            $optionCount++;
        }

        $unitTotal = $basePrice + $optionsPrice;
        $lineTotal = $unitTotal * $item['quantity'];

        return [
            'product_id' => $item['product_id'],
            'quantity' => $item['quantity'],
            'unit_price' => round($basePrice, 2),
            'options_price' => round($optionsPrice, 2),
            'option_count' => $optionCount,
            'unit_total' => round($unitTotal, 2),
            'total_excl_vat' => round($lineTotal, 2),
            'vat_rate' => $item['vat_rate'],
            'vat_amount' => round($lineTotal * ($item['vat_rate'] / 100), 2),
            'total_incl_vat' => round($lineTotal * (1 + $item['vat_rate'] / 100), 2),
        ];
    }

    /**
     * Run benchmark
     *
     * @param string $scenario Cart size: small_cart, medium_cart, large_cart, xl_cart
     * @param int $iterations Number of calculation iterations
     * @return array Benchmark results
     */
    public static function benchmark(string $scenario = 'large_cart', int $iterations = 100): array
    {
        $cart = DataLoader::cartScenario($scenario);

        // Warm up
        self::calculate($cart, 10);

        $times = [];
        $memoryStart = memory_get_usage(true);

        for ($i = 0; $i < $iterations; $i++) {
            $start = hrtime(true);

            $result = self::calculate($cart, 10); // 10% discount

            $end = hrtime(true);
            $times[] = ($end - $start) / 1_000_000;
        }

        $memoryEnd = memory_get_usage(true);

        sort($times);

        return [
            'operation' => 'cart_calculation',
            'scenario' => $scenario,
            'item_count' => $cart['item_count'],
            'iterations' => $iterations,
            'avg_time_ms' => round(array_sum($times) / count($times), 3),
            'min_time_ms' => round(min($times), 3),
            'max_time_ms' => round(max($times), 3),
            'std_dev_ms' => round(self::standardDeviation($times), 3),
            'p25_time_ms' => round($times[(int)(count($times) * 0.25)], 3),
            'p50_time_ms' => round($times[(int)(count($times) * 0.50)], 3),
            'p75_time_ms' => round($times[(int)(count($times) * 0.75)], 3),
            'p95_time_ms' => round($times[(int)(count($times) * 0.95)], 3),
            'p99_time_ms' => round($times[(int)(count($times) * 0.99)], 3),
            'memory_used_mb' => round(($memoryEnd - $memoryStart) / 1024 / 1024, 2),
            'total_time_ms' => round(array_sum($times), 3),
        ];
    }

    private static function standardDeviation(array $data): float
    {
        $count = count($data);
        if ($count === 0) return 0;

        $mean = array_sum($data) / $count;
        $squaredDiffs = array_map(fn($x) => pow($x - $mean, 2), $data);

        return sqrt(array_sum($squaredDiffs) / $count);
    }
}
