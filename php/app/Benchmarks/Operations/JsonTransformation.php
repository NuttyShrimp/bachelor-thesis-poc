<?php

namespace App\Benchmarks\Operations;

use App\Benchmarks\DataLoader;

/**
 * JSON TRANSFORMATION BENCHMARK
 *
 * Transforms nested shop data into API response format.
 * Simulates ExtendedShopTransformer from production.
 *
 * ALGORITHM:
 * 1. Transform shop base data
 * 2. Loop through categories
 * 3. For each category, transform products
 * 4. For each product, calculate pricing, format values
 * 5. Build nested response structure
 * 6. Encode to JSON
 *
 * SWIFT IMPLEMENTATION NOTES:
 * ===========================
 * - Use Codable protocol for automatic JSON serialization
 * - Define Shop, Category, Product as Codable structs
 * - Swift's JSONEncoder is highly optimized (faster than json_encode)
 * - Use CodingKeys for field name mapping (snake_case <-> camelCase)
 *
 * Example Swift:
 * ```swift
 * struct Product: Codable {
 *     let id: Int
 *     let name: String
 *     let slug: String
 *     let description: String
 *     let pricing: ProductPricing
 *     let availability: ProductAvailability
 *
 *     enum CodingKeys: String, CodingKey {
 *         case id, name, slug, description, pricing, availability
 *     }
 * }
 *
 * struct ProductPricing: Codable {
 *     let priceExclVat: Decimal
 *     let priceInclVat: Decimal
 *     let vatRate: Int
 *     let vatAmount: Decimal
 *     let currency: String
 *     let formatted: String
 *
 *     enum CodingKeys: String, CodingKey {
 *         case priceExclVat = "price_excl_vat"
 *         case priceInclVat = "price_incl_vat"
 *         case vatRate = "vat_rate"
 *         case vatAmount = "vat_amount"
 *         case currency, formatted
 *     }
 * }
 *
 * struct ShopTransformer {
 *     static func transform(_ shop: Shop) -> TransformedShop {
 *         TransformedShop(
 *             id: shop.id,
 *             name: shop.name,
 *             slug: slugify(shop.name),
 *             categories: shop.categories.map(transformCategory)
 *         )
 *     }
 *
 *     static func encode(_ shop: TransformedShop) throws -> Data {
 *         let encoder = JSONEncoder()
 *         encoder.outputFormatting = .prettyPrinted
 *         return try encoder.encode(shop)
 *     }
 * }
 * ```
 *
 * COMPLEXITY: O(c * p) where c = categories, p = products per category
 */
class JsonTransformation
{
    /**
     * Transform shop to API response format
     */
    public static function transformShop(array $shop): array
    {
        $categories = $shop['categories'] ?? [];
        $productCount = self::countProducts($shop);

        return [
            'id' => $shop['id'],
            'name' => $shop['name'],
            'slug' => self::slugify($shop['name']),
            'meta' => [
                'category_count' => count($categories),
                'product_count' => $productCount,
            ],
            'categories' => array_map(
                fn($cat) => self::transformCategory($cat),
                $categories
            ),
            'transformed_at' => date('c'),
        ];
    }

    /**
     * Transform category
     */
    private static function transformCategory(array $category): array
    {
        $products = $category['products'] ?? [];

        return [
            'id' => $category['id'],
            'name' => $category['name'],
            'slug' => self::slugify($category['name']),
            'product_count' => count($products),
            'products' => array_map(
                fn($prod) => self::transformProduct($prod),
                $products
            ),
        ];
    }

    /**
     * Transform product with pricing calculations
     */
    private static function transformProduct(array $product): array
    {
        $price = $product['price'] ?? 0;
        $vatRate = $product['vat_rate'] ?? 21;
        $priceInclVat = $price * (1 + $vatRate / 100);

        return [
            'id' => $product['id'],
            'name' => $product['name'],
            'slug' => self::slugify($product['name']),
            'description' => $product['description'] ?? '',
            'pricing' => [
                'price_excl_vat' => round($price, 2),
                'price_incl_vat' => round($priceInclVat, 2),
                'vat_rate' => $vatRate,
                'vat_amount' => round($priceInclVat - $price, 2),
                'currency' => 'EUR',
                'formatted' => self::formatPrice($priceInclVat),
            ],
            'availability' => [
                'in_stock' => true,
                'quantity' => rand(0, 100),
                'status' => 'available',
            ],
        ];
    }

    /**
     * Create URL-safe slug from string
     *
     * SWIFT NOTE: Use a similar approach with String manipulation
     * ```swift
     * extension String {
     *     var slugified: String {
     *         self.lowercased()
     *             .folding(options: .diacriticInsensitive, locale: .current)
     *             .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
     *             .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
     *     }
     * }
     * ```
     */
    private static function slugify(string $text): string
    {
        // Replace non-alphanumeric characters with dashes
        $text = preg_replace('~[^\pL\d]+~u', '-', $text);
        // Transliterate
        $text = iconv('utf-8', 'us-ascii//TRANSLIT', $text) ?: $text;
        // Remove unwanted characters
        $text = preg_replace('~[^-\w]+~', '', $text);
        // Trim dashes
        $text = trim($text, '-');
        // Remove duplicate dashes
        $text = preg_replace('~-+~', '-', $text);

        return strtolower($text);
    }

    /**
     * Format price for display
     */
    private static function formatPrice(float $price): string
    {
        return '€' . number_format($price, 2, ',', '.');
    }

    /**
     * Count total products in shop
     */
    private static function countProducts(array $shop): int
    {
        $count = 0;
        foreach ($shop['categories'] ?? [] as $category) {
            $count += count($category['products'] ?? []);
        }
        return $count;
    }

    /**
     * Run benchmark
     */
    public static function benchmark(int $iterations = 100): array
    {
        $shop = DataLoader::shop();

        // Warm up
        self::transformShop($shop);

        $times = [];
        $jsonSizes = [];
        $memoryStart = memory_get_usage(true);

        for ($i = 0; $i < $iterations; $i++) {
            $start = hrtime(true);

            $result = self::transformShop($shop);
            // Also encode to JSON to measure full serialization cost
            $json = json_encode($result);

            $end = hrtime(true);
            $times[] = ($end - $start) / 1_000_000;
            $jsonSizes[] = strlen($json);
        }

        $memoryEnd = memory_get_usage(true);

        sort($times);

        $categoryCount = count($shop['categories'] ?? []);
        $productCount = self::countProducts($shop);

        return [
            'operation' => 'json_transformation',
            'category_count' => $categoryCount,
            'product_count' => $productCount,
            'iterations' => $iterations,
            'avg_time_ms' => round(array_sum($times) / count($times), 3),
            'min_time_ms' => round(min($times), 3),
            'max_time_ms' => round(max($times), 3),
            'std_dev_ms' => round(self::standardDeviation($times), 3),
            'p50_time_ms' => round($times[(int)(count($times) * 0.50)], 3),
            'p95_time_ms' => round($times[(int)(count($times) * 0.95)], 3),
            'p99_time_ms' => round($times[(int)(count($times) * 0.99)], 3),
            'memory_used_mb' => round(($memoryEnd - $memoryStart) / 1024 / 1024, 2),
            'avg_json_size_kb' => round(array_sum($jsonSizes) / count($jsonSizes) / 1024, 2),
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
