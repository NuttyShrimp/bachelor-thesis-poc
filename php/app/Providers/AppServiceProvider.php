<?php

namespace App\Providers;

use App\Benchmarks\DataLoader;
use Illuminate\Support\Facades\Vite;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->singleton(DataLoader::class, function ($app) {
            return DataLoader::getInstance();
        });
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Vite::prefetch(concurrency: 3);
        ini_set('memory_limit', '2G');

        // Preload benchmark data in memory if running under Octane worker
        if (isset($_ENV['OCTANE_SERVER']) && class_exists(DataLoader::class)) {
            try {
                DataLoader::getInstance()->preloadData();
            } catch (\Throwable $e) {
                // Ignore if files do not exist yet or other boot-time issues
            }
        }
    }
}
