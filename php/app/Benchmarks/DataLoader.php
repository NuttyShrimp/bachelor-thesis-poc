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
    private static bool $isCacheEnabled = false;
    private static array $cache = [];

    /**
     * Enable in-memory caching
     */
    public static function enableCache(): void
    {
        self::$isCacheEnabled = true;
    }

    /**
     * Disable in-memory caching and clear the cache
     */
    public static function disableCache(): void
    {
        self::$isCacheEnabled = false;
        self::$cache = [];
    }

    /**
     * Preload all data into memory
     */
    public static function preloadData(): void
    {
        self::enableCache();
        self::orders();
        self::products();
        self::shop();
        self::cartScenarios();
        
        // Preload common scenarios
        foreach (['small_cart', 'medium_cart', 'large_cart', 'xl_cart'] as $size) {
            self::cartScenario($size);
        }
    }

    /**
     * Get order data including products and options
     */
    public static function orders(): array
    {
        return self::getCachedOrLoad('orders', 'orders.json');
    }

    /**
     * Get product catalog data
     */
    public static function products(): array
    {
        return self::getCachedOrLoad('products', 'products.json');
    }

    /**
     * Get shop data with categories and products
     */
    public static function shop(): array
    {
        return self::getCachedOrLoad('shop', 'shop.json');
    }

    /**
     * Get all cart scenarios
     */
    public static function cartScenarios(): array
    {
        return self::getCachedOrLoad('cartScenarios', 'cart_scenarios.json');
    }

    /**
     * Get a specific cart scenario by size
     *
     * @param string $size One of: small_cart, medium_cart, large_cart, xl_cart
     */
    public static function cartScenario(string $size): array
    {
        $cacheKey = "cartScenario_{$size}";
        if (self::$isCacheEnabled && isset(self::$cache[$cacheKey])) {
            return self::$cache[$cacheKey];
        }

        $scenarios = self::cartScenarios();
        $result = $scenarios[$size] ?? $scenarios['medium_cart'];

        if (self::$isCacheEnabled) {
            self::$cache[$cacheKey] = $result;
        }

        return $result;
    }

    /**
     * Helper to get from cache or load from file
     */
    private static function getCachedOrLoad(string $key, string $filename): array
    {
        if (self::$isCacheEnabled && isset(self::$cache[$key])) {
            return self::$cache[$key];
        }

        $result = self::load($filename);

        if (self::$isCacheEnabled) {
            self::$cache[$key] = $result;
        }

        return $result;
    }

    /**
     * Load a JSON file
     */
    private static function load(string $filename): array
    {
        $path = base_path('../data/' . $filename);

        if (!File::exists($path)) {
            throw new \RuntimeException("Benchmark data file not found: {$path}. Run 'php artisan benchmark:generate-data' first.");
        }

        return json_decode(File::get($path), true);
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
            if (!File::exists(base_path('../data/' . $file))) {
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
            if (!File::exists(base_path('../data/' . $file))) {
                $missing[] = $file;
            }
        }

        return $missing;
    }
}
