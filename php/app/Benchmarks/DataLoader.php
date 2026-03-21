<?php

namespace App\Benchmarks;

use Illuminate\Support\Facades\File;

/**
 * DATA LOADER
 *
 * Loads benchmark data from static JSON files.
 * This eliminates database latency from benchmark measurements.
 *
 * SWIFT IMPLEMENTATION NOTES:
 * - Use JSONDecoder with Codable structs
 * - Consider lazy loading with lazy var
 * - File reading is similar: FileManager.default.contents(atPath:)
 */
class DataLoader
{
    private static array $cache = [];

    /**
     * Get order data including products and options
     */
    public static function orders(): array
    {
        return self::load('orders.json');
    }

    /**
     * Get product catalog data
     */
    public static function products(): array
    {
        return self::load('products.json');
    }

    /**
     * Get shop data with categories and products
     */
    public static function shop(): array
    {
        return self::load('shop.json');
    }

    /**
     * Get all cart scenarios
     */
    public static function cartScenarios(): array
    {
        return self::load('cart_scenarios.json');
    }

    /**
     * Get a specific cart scenario by size
     *
     * @param string $size One of: small_cart, medium_cart, large_cart, xl_cart
     */
    public static function cartScenario(string $size): array
    {
        $scenarios = self::cartScenarios();
        return $scenarios[$size] ?? $scenarios['medium_cart'];
    }

    /**
     * Load and cache a JSON file
     */
    private static function load(string $filename): array
    {
        if (!isset(self::$cache[$filename])) {
            $path = base_path('data/' . $filename);

            if (!File::exists($path)) {
                throw new \RuntimeException("Benchmark data file not found: {$path}. Run 'php artisan benchmark:generate-data' first.");
            }

            self::$cache[$filename] = json_decode(File::get($path), true);
        }

        return self::$cache[$filename];
    }

    /**
     * Clear the cache (useful for testing)
     */
    public static function clearCache(): void
    {
        self::$cache = [];
    }

    /**
     * Check if all required data files exist
     */
    public static function dataFilesExist(): bool
    {
        $requiredFiles = ['orders.json', 'products.json', 'shop.json', 'cart_scenarios.json'];

        foreach ($requiredFiles as $file) {
            if (!File::exists(base_path('data/' . $file))) {
                return false;
            }
        }

        return true;
    }

    /**
     * Get list of missing data files
     */
    public static function getMissingFiles(): array
    {
        $requiredFiles = ['orders.json', 'products.json', 'shop.json', 'cart_scenarios.json'];
        $missing = [];

        foreach ($requiredFiles as $file) {
            if (!File::exists(base_path('data/' . $file))) {
                $missing[] = $file;
            }
        }

        return $missing;
    }
}