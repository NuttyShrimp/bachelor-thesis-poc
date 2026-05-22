<?php

namespace App\Benchmarks;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Log;

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
    private static ?DataLoader $instance = null;
    private static bool $isCacheEnabled = false;
    private static array $cache = [];

    /**
     * Get the globally shared DataLoader instance.
     */
    public static function getInstance(): self
    {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    /**
     * Enable in-memory caching
     */
    public function enableCache(): void
    {
        self::$isCacheEnabled = true;
        Cache::forever('dataloader:is_cache_enabled', true);
    }

    /**
     * Disable in-memory caching and clear the cache
     */
    public function disableCache(): void
    {
        self::$isCacheEnabled = false;
        self::$cache = [];
        Cache::forget('dataloader:is_cache_enabled');
        foreach (['orders', 'products', 'shop', 'cartScenarios'] as $key) {
            Cache::forget("dataloader:{$key}");
        }
        foreach (['small_cart', 'medium_cart', 'large_cart', 'xl_cart'] as $size) {
            Cache::forget("dataloader:cartScenario_{$size}");
        }
    }

    /**
     * Check if caching is enabled
     */
    public function isCacheEnabled(): bool
    {
        return self::$isCacheEnabled || Cache::get('dataloader:is_cache_enabled', false);
    }

    /**
     * Preload all data into memory
     */
    public function preloadData(): void
    {
        $this->enableCache();
        $this->orders();
        $this->products();
        $this->shop();
        $this->cartScenarios();

        // Preload common scenarios
        foreach (['small_cart', 'medium_cart', 'large_cart', 'xl_cart'] as $size) {
            $this->cartScenario($size);
        }
    }

    /**
     * Get order data including products and options
     */
    public function orders(): array
    {
        return $this->getCachedOrLoad('orders', 'orders.json');
    }

    /**
     * Get product catalog data
     */
    public function products(): array
    {
        return $this->getCachedOrLoad('products', 'products.json');
    }

    /**
     * Get shop data with categories and products
     */
    public function shop(): array
    {
        return $this->getCachedOrLoad('shop', 'shop.json');
    }

    /**
     * Get all cart scenarios
     */
    public function cartScenarios(): array
    {
        return $this->getCachedOrLoad('cartScenarios', 'cart_scenarios.json');
    }

    /**
     * Get a specific cart scenario by size
     *
     * @param string $size One of: small_cart, medium_cart, large_cart, xl_cart
     */
    public function cartScenario(string $size): array
    {
        $cacheKey = "cartScenario_{$size}";
        if (self::$isCacheEnabled && isset(self::$cache[$cacheKey])) {
            Log::info('Loading memory cached for '.$cacheKey);
            return self::$cache[$cacheKey];
        }

        $isCachedInPersistentStore = Cache::get('dataloader:is_cache_enabled', false);
        if ($isCachedInPersistentStore) {
            $cached = Cache::get("dataloader:{$cacheKey}");
            if ($cached !== null) {
                Log::info('Loading persistent cached for '.$cacheKey);
                if (self::$isCacheEnabled) {
                    self::$cache[$cacheKey] = $cached;
                }
                return $cached;
            }
        }

        $scenarios = $this->cartScenarios();
        $result = $scenarios[$size] ?? $scenarios['medium_cart'];

        if (self::$isCacheEnabled) {
            self::$cache[$cacheKey] = $result;
        }

        if ($isCachedInPersistentStore || self::$isCacheEnabled) {
            Cache::forever("dataloader:{$cacheKey}", $result);
        }

        return $result;
    }

    /**
     * Helper to get from cache or load from file
     */
    private function getCachedOrLoad(string $key, string $filename): array
    {
        if (self::$isCacheEnabled && isset(self::$cache[$key])) {
            Log::info('Loading memory cached for '.$key);
            return self::$cache[$key];
        }

        $isCachedInPersistentStore = Cache::get('dataloader:is_cache_enabled', false);
        if ($isCachedInPersistentStore) {
            $cached = Cache::get("dataloader:{$key}");
            if ($cached !== null) {
                Log::info('Loading persistent cached for '.$key);
                if (self::$isCacheEnabled) {
                    self::$cache[$key] = $cached;
                }
                return $cached;
            }
        }

        $result = $this->load($filename);

        if (self::$isCacheEnabled) {
            self::$cache[$key] = $result;
        }

        if ($isCachedInPersistentStore || self::$isCacheEnabled) {
            Cache::forever("dataloader:{$key}", $result);
        }

        return $result;
    }

    /**
     * Load a JSON file
     */
    private function load(string $filename): array
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
    public function clearCache(): void
    {
        self::$cache = [];
        foreach (['orders', 'products', 'shop', 'cartScenarios'] as $key) {
            Cache::forget("dataloader:{$key}");
        }
        foreach (['small_cart', 'medium_cart', 'large_cart', 'xl_cart'] as $size) {
            Cache::forget("dataloader:cartScenario_{$size}");
        }
    }

    /**
     * Check if all required data files exist
     */
    public function dataFilesExist(): bool
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
    public function getMissingFiles(): array
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
