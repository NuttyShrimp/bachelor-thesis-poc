<?php

namespace App\Benchmarks\Operations;

use App\Benchmarks\DataLoader;
use App\Benchmarks\Dtos\ProductSettingsData;
use App\Benchmarks\Dtos\OrderSettingsData;
use App\Benchmarks\Dtos\OrderProductsData;

/**
 * DTO MAPPING BENCHMARK
 *
 * This is the MOST CRITICAL benchmark for PHP vs Swift comparison.
 * It measures the overhead of:
 * 1. JSON string decoding
 * 2. Array to object mapping
 * 3. Nested object instantiation
 * 4. Memory allocation for object graphs
 *
 * In production BakerOnline, this happens on EVERY request:
 * - Product pages load products with settings_json, translations_json
 * - Order pages load orders with products_json, settings_json
 * - The DTO mapping is a significant portion of response time
 *
 * SWIFT IMPLEMENTATION NOTES:
 * ===========================
 * ```swift
 * // Swift uses Codable for automatic JSON -> struct mapping
 * struct ProductSettings: Codable {
 *     let seo: SeoData?
 *     let photo: String?
 *     let price: PriceSettings?
 *     // ... nested structs
 * }
 *
 * func mapProductSettings(from jsonData: Data) throws -> ProductSettings {
 *     let decoder = JSONDecoder()
 *     return try decoder.decode(ProductSettings.self, from: jsonData)
 * }
 *
 * // Benchmark:
 * func benchmarkProductMapping(iterations: Int) -> BenchmarkResult {
 *     let jsonData = loadProductsJson()
 *     var times: [Double] = []
 *
 *     for _ in 0..<iterations {
 *         let start = DispatchTime.now()
 *
 *         for product in products {
 *             let settings = try! decoder.decode(ProductSettings.self, from: product.settingsJsonData)
 *             // Access nested properties to force full decode
 *             _ = settings.seo?.title
 *             _ = settings.photos_fs?.items.count
 *         }
 *
 *         let end = DispatchTime.now()
 *         times.append(Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000)
 *     }
 *
 *     return BenchmarkResult(times: times)
 * }
 * ```
 *
 * KEY DIFFERENCES:
 * - PHP: json_decode() + manual object instantiation in constructors
 * - Swift: JSONDecoder.decode() with Codable - often faster due to compile-time type info
 * - Swift structs are value types (stack allocation), PHP objects are heap-allocated
 *
 * COMPLEXITY: O(n * d) where n = records, d = depth of nested objects
 */
class DtoMapping
{
    /**
     * Map product settings JSON to DTO
     *
     * @param array $product Raw product data with settings_json
     * @return ProductSettingsData Mapped DTO
     */
    public static function mapProductSettings(array $product): ProductSettingsData
    {
        $settings = $product['settings_json'] ?? [];
        return new ProductSettingsData($settings);
    }

    /**
     * Map order settings JSON to DTO
     *
     * @param array $order Raw order data with settings_json
     * @return OrderSettingsData Mapped DTO
     */
    public static function mapOrderSettings(array $order): OrderSettingsData
    {
        $settings = $order['settings_json'] ?? [];
        return new OrderSettingsData($settings);
    }

    /**
     * Map order products JSON to DTO
     *
     * @param array $order Raw order data with products_json
     * @return OrderProductsData Mapped DTO
     */
    public static function mapOrderProducts(array $order): OrderProductsData
    {
        $products = $order['products_json'] ?? [];
        return new OrderProductsData($products);
    }

    /**
     * Full order mapping - both products and settings
     * This is what happens on every order detail page load
     */
    public static function mapFullOrder(array $order): array
    {
        return [
            'products' => self::mapOrderProducts($order),
            'settings' => self::mapOrderSettings($order),
        ];
    }

    /**
     * Benchmark: Product settings DTO mapping
     *
     * Maps all products' settings_json to DTOs
     */
    public static function benchmarkProductSettings(int $iterations = 50): array
    {
        $productsData = DataLoader::products();
        $products = $productsData['products'] ?? [];

        if (empty($products)) {
            return ['error' => 'No products loaded'];
        }

        // Warm up
        foreach (array_slice($products, 0, 10) as $product) {
            self::mapProductSettings($product);
        }

        $times = [];
        $memoryStart = memory_get_usage(true);
        $dtoCount = 0;

        for ($i = 0; $i < $iterations; $i++) {
            $start = hrtime(true);

            foreach ($products as $product) {
                $dto = self::mapProductSettings($product);
                // Access nested properties to ensure full mapping
                $_ = $dto->seo?->title;
                $_ = $dto->photos_fs?->items;
                $_ = $dto->stock?->soldout;
                $dtoCount++;
            }

            $end = hrtime(true);
            $times[] = ($end - $start) / 1_000_000;
        }

        $memoryEnd = memory_get_usage(true);

        sort($times);

        return [
            'operation' => 'dto_mapping_product_settings',
            'product_count' => count($products),
            'total_mappings' => $dtoCount,
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
            'avg_time_per_product_ms' => round(array_sum($times) / count($times) / count($products), 6),
            'total_time_ms' => round(array_sum($times), 3),
        ];
    }

    /**
     * Benchmark: Order settings DTO mapping
     *
     * Maps all orders' settings_json to DTOs
     * This tests the 48+ nested payment/metadata objects
     */
    public static function benchmarkOrderSettings(int $iterations = 50): array
    {
        $ordersData = DataLoader::orders();
        $orders = $ordersData['orders'] ?? [];

        if (empty($orders)) {
            return ['error' => 'No orders loaded'];
        }

        // Warm up
        foreach (array_slice($orders, 0, 10) as $order) {
            self::mapOrderSettings($order);
        }

        $times = [];
        $memoryStart = memory_get_usage(true);
        $dtoCount = 0;

        for ($i = 0; $i < $iterations; $i++) {
            $start = hrtime(true);

            foreach ($orders as $order) {
                $dto = self::mapOrderSettings($order);
                // Access nested properties
                $_ = $dto->user?->email;
                $_ = $dto->piggy?->qr?->url;
                $_ = $dto->stripe?->payment_intent_id;
                $dtoCount++;
            }

            $end = hrtime(true);
            $times[] = ($end - $start) / 1_000_000;
        }

        $memoryEnd = memory_get_usage(true);

        sort($times);

        return [
            'operation' => 'dto_mapping_order_settings',
            'order_count' => count($orders),
            'total_mappings' => $dtoCount,
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
            'avg_time_per_order_ms' => round(array_sum($times) / count($times) / count($orders), 6),
            'total_time_ms' => round(array_sum($times), 3),
        ];
    }

    /**
     * Benchmark: Order products DTO mapping
     *
     * Maps all orders' products_json to DTOs
     * This is the HEAVIEST operation - deeply nested product data
     */
    public static function benchmarkOrderProducts(int $iterations = 50): array
    {
        $ordersData = DataLoader::orders();
        $orders = $ordersData['orders'] ?? [];

        if (empty($orders)) {
            return ['error' => 'No orders loaded'];
        }

        // Warm up
        foreach (array_slice($orders, 0, 10) as $order) {
            self::mapOrderProducts($order);
        }

        $times = [];
        $memoryStart = memory_get_usage(true);
        $dtoCount = 0;
        $totalProducts = 0;

        for ($i = 0; $i < $iterations; $i++) {
            $start = hrtime(true);

            foreach ($orders as $order) {
                $dto = self::mapOrderProducts($order);
                // Access deeply nested properties
                foreach ($dto->items as $item) {
                    $_ = $item->product?->name;
                    $_ = $item->product?->min_max?->amount?->max;
                    $_ = $item->calculated_prices?->price;
                    foreach ($item->options as $opt) {
                        $_ = $opt->product?->name;
                    }
                    $totalProducts++;
                }
                $dtoCount++;
            }

            $end = hrtime(true);
            $times[] = ($end - $start) / 1_000_000;
        }

        $memoryEnd = memory_get_usage(true);

        sort($times);

        return [
            'operation' => 'dto_mapping_order_products',
            'order_count' => count($orders),
            'total_product_items' => $totalProducts,
            'total_mappings' => $dtoCount,
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
            'avg_time_per_order_ms' => round(array_sum($times) / count($times) / count($orders), 6),
            'total_time_ms' => round(array_sum($times), 3),
        ];
    }

    /**
     * Benchmark: Full order mapping (products + settings)
     *
     * This simulates loading an order detail page
     */
    public static function benchmarkFullOrder(int $iterations = 50): array
    {
        $ordersData = DataLoader::orders();
        $orders = $ordersData['orders'] ?? [];

        if (empty($orders)) {
            return ['error' => 'No orders loaded'];
        }

        // Warm up
        foreach (array_slice($orders, 0, 5) as $order) {
            self::mapFullOrder($order);
        }

        $times = [];
        $memoryStart = memory_get_usage(true);

        for ($i = 0; $i < $iterations; $i++) {
            $start = hrtime(true);

            foreach ($orders as $order) {
                $mapped = self::mapFullOrder($order);
                // Access data to ensure full mapping
                $_ = $mapped['settings']->user?->email;
                foreach ($mapped['products']->items as $item) {
                    $_ = $item->product?->name;
                }
            }

            $end = hrtime(true);
            $times[] = ($end - $start) / 1_000_000;
        }

        $memoryEnd = memory_get_usage(true);

        sort($times);

        return [
            'operation' => 'dto_mapping_full_order',
            'order_count' => count($orders),
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
            'avg_time_per_order_ms' => round(array_sum($times) / count($times) / count($orders), 6),
            'total_time_ms' => round(array_sum($times), 3),
        ];
    }

    /**
     * Run all DTO mapping benchmarks
     */
    public static function benchmark(string $operation = "all", int $iterations = 50): array
    {
        if ($operation == "all") {
            return [
                'product_settings' => self::benchmarkProductSettings($iterations),
                'order_settings' => self::benchmarkOrderSettings($iterations),
                'order_products' => self::benchmarkOrderProducts($iterations),
                'full_order' => self::benchmarkFullOrder($iterations),
            ];
        }
        return match ($operation) {
            'product_settings' => [$operation => self::benchmarkProductSettings($iterations)],
            'order_settings' => [$operation => self::benchmarkOrderSettings($iterations)],
            'order_products' => [$operation => self::benchmarkOrderProducts($iterations)],
            'full_order' => [$operation => self::benchmarkFullOrder($iterations)],
            default => throw new \InvalidArgumentException("Unknown operation: {$operation}"),
        };
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
