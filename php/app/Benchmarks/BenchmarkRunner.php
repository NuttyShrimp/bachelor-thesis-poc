<?php

namespace App\Benchmarks;

use App\Benchmarks\Operations\VatCalculation;
use App\Benchmarks\Operations\CartCalculation;
use App\Benchmarks\Operations\JsonTransformation;
use App\Benchmarks\Operations\ExcelGeneration;
use App\Benchmarks\Operations\PdfGeneration;
use App\Benchmarks\Operations\DtoMapping;

/**
 * BENCHMARK RUNNER
 *
 * Orchestrates all benchmark operations and collects results.
 * This is the main entry point for running benchmarks from HTTP or CLI.
 *
 * SWIFT IMPLEMENTATION NOTES:
 * ===========================
 * - Create a similar BenchmarkRunner struct/class in Swift
 * - Use DispatchTime.now() for timing (similar to hrtime())
 * - Consider using XCTest's measure {} for built-in benchmarking
 * - For HTTP API, use Vapor or Hummingbird framework
 *
 * Example Swift:
 * ```swift
 * struct BenchmarkRunner {
 *     static func runAll() -> BenchmarkResults {
 *         var results: [String: BenchmarkResult] = [:]
 *
 *         results["vat_calculation"] = VatCalculation.benchmark()
 *         results["cart_calculation"] = CartCalculation.benchmark()
 *         results["json_transformation"] = JsonTransformation.benchmark()
 *         results["excel_generation"] = ExcelGeneration.benchmark()
 *         results["pdf_generation"] = PdfGeneration.benchmark()
 *
 *         return BenchmarkResults(
 *             timestamp: Date(),
 *             runtime: "Swift",
 *             results: results
 *         )
 *     }
 * }
 * ```
 */
class BenchmarkRunner
{
    /**
     * Available benchmark operations
     */
    public const OPERATIONS = [
        'dto_mapping' => DtoMapping::class,
        'vat_calculation' => VatCalculation::class,
        'cart_calculation' => CartCalculation::class,
        'json_transformation' => JsonTransformation::class,
        'excel_generation' => ExcelGeneration::class,
        'pdf_generation_single' => PdfGeneration::class,
        'pdf_generation_zip' => PdfGeneration::class,
    ];

    /**
     * Run all benchmarks
     *
     * @param array $options Configuration options
     * @return array Complete benchmark results
     */
    public static function runAll(array $options = []): array
    {
        $startTime = hrtime(true);

        $results = [
            'meta' => self::getMetadata(),
            'benchmarks' => [],
        ];

        // DTO Mapping - THE MOST CRITICAL benchmark for PHP vs Swift
        $results['benchmarks']['dto_mapping'] = DtoMapping::benchmark(
            $options['dto_iterations'] ?? 50
        );

        // VAT Calculation - multiple cart sizes
        $results['benchmarks']['vat_calculation'] = [];
        foreach (['small_cart', 'medium_cart', 'large_cart', 'xl_cart'] as $scenario) {
            $results['benchmarks']['vat_calculation'][$scenario] = VatCalculation::benchmark(
                $scenario,
                $options['iterations'] ?? 100
            );
        }

        // Cart Calculation - multiple cart sizes
        $results['benchmarks']['cart_calculation'] = [];
        foreach (['small_cart', 'medium_cart', 'large_cart', 'xl_cart'] as $scenario) {
            $results['benchmarks']['cart_calculation'][$scenario] = CartCalculation::benchmark(
                $scenario,
                $options['iterations'] ?? 100
            );
        }

        // JSON Transformation
        $results['benchmarks']['json_transformation'] = JsonTransformation::benchmark(
            $options['iterations'] ?? 100
        );

        // Excel Generation (fewer iterations - it's slow)
        $results['benchmarks']['excel_generation'] = ExcelGeneration::benchmark(
            $options['excel_iterations'] ?? 10
        );

        // PDF Generation - Single
        $results['benchmarks']['pdf_generation_single'] = PdfGeneration::benchmarkSingle(
            $options['pdf_iterations'] ?? 50
        );

        // PDF Generation - ZIP
        $results['benchmarks']['pdf_generation_zip'] = PdfGeneration::benchmarkZip(
            $options['pdf_count'] ?? 50,
            $options['zip_iterations'] ?? 5
        );

        $endTime = hrtime(true);

        $results['meta']['total_benchmark_time_ms'] = round(($endTime - $startTime) / 1_000_000, 2);
        $results['meta']['completed_at'] = date('c');

        return $results;
    }

    /**
     * Run a single benchmark operation
     *
     * @param string $operation Operation name
     * @param array $options Configuration options
     * @return array Benchmark results
     */
    public static function run(string $operation, array $options = []): array
    {
        $startTime = hrtime(true);

        $result = match ($operation) {
            'dto_mapping' => DtoMapping::benchmark(
                $options['iterations'] ?? 50
            ),
            'dto_mapping_product_settings' => DtoMapping::benchmarkProductSettings(
                $options['iterations'] ?? 50
            ),
            'dto_mapping_order_settings' => DtoMapping::benchmarkOrderSettings(
                $options['iterations'] ?? 50
            ),
            'dto_mapping_order_products' => DtoMapping::benchmarkOrderProducts(
                $options['iterations'] ?? 50
            ),
            'dto_mapping_full_order' => DtoMapping::benchmarkFullOrder(
                $options['iterations'] ?? 50
            ),
            'vat_calculation' => VatCalculation::benchmark(
                $options['scenario'] ?? 'large_cart',
                $options['iterations'] ?? 100
            ),
            'cart_calculation' => CartCalculation::benchmark(
                $options['scenario'] ?? 'large_cart',
                $options['iterations'] ?? 100
            ),
            'json_transformation' => JsonTransformation::benchmark(
                $options['iterations'] ?? 100
            ),
            'excel_generation' => ExcelGeneration::benchmark(
                $options['iterations'] ?? 10
            ),
            'pdf_generation_single' => PdfGeneration::benchmarkSingle(
                $options['iterations'] ?? 50
            ),
            'pdf_generation_zip' => PdfGeneration::benchmarkZip(
                $options['pdf_count'] ?? 50,
                $options['iterations'] ?? 5
            ),
            default => throw new \InvalidArgumentException("Unknown operation: {$operation}"),
        };

        $endTime = hrtime(true);

        return [
            'meta' => self::getMetadata(),
            'benchmark' => $result,
            'execution_time_ms' => round(($endTime - $startTime) / 1_000_000, 2),
        ];
    }

    /**
     * Get system metadata for benchmark context
     */
    public static function getMetadata(): array
    {
        $isOctane = isset($_SERVER['LARAVEL_OCTANE']) ||
                    class_exists(\Laravel\Octane\Octane::class) && app()->bound('octane');

        return [
            'timestamp' => date('c'),
            'php_version' => PHP_VERSION,
            'laravel_version' => app()->version(),
            'runtime_mode' => $isOctane ? 'octane' : 'php-fpm',
            'octane_server' => $isOctane ? ($_SERVER['OCTANE_SERVER'] ?? 'unknown') : null,
            'os' => PHP_OS,
            'architecture' => php_uname('m'),
            'memory_limit' => ini_get('memory_limit'),
            'opcache_enabled' => function_exists('opcache_get_status') && opcache_get_status() !== false,
        ];
    }

    /**
     * List available operations
     */
    public static function listOperations(): array
    {
        return [
            [
                'name' => 'dto_mapping',
                'description' => 'JSON to DTO mapping - THE CORE PHP vs Swift comparison',
                'complexity' => 'O(n * d) - records * nested depth',
                'scenarios' => null,
                'sub_benchmarks' => [
                    'dto_mapping_product_settings',
                    'dto_mapping_order_settings',
                    'dto_mapping_order_products',
                    'dto_mapping_full_order',
                ],
            ],
            [
                'name' => 'vat_calculation',
                'description' => 'Calculate VAT for orders with nested items and options',
                'complexity' => 'O(n * m) - items * options',
                'scenarios' => ['small_cart', 'medium_cart', 'large_cart', 'xl_cart'],
            ],
            [
                'name' => 'cart_calculation',
                'description' => 'Calculate cart totals with discounts',
                'complexity' => 'O(n * m) - items * options',
                'scenarios' => ['small_cart', 'medium_cart', 'large_cart', 'xl_cart'],
            ],
            [
                'name' => 'json_transformation',
                'description' => 'Transform shop data to API response format',
                'complexity' => 'O(c * p) - categories * products',
                'scenarios' => null,
            ],
            [
                'name' => 'excel_generation',
                'description' => 'Generate production list Excel file',
                'complexity' => 'O(d * c * p * o) - dates * categories * products * options',
                'scenarios' => null,
            ],
            [
                'name' => 'pdf_generation_single',
                'description' => 'Generate single PDF invoice',
                'complexity' => 'O(n) with high constant factor',
                'scenarios' => null,
            ],
            [
                'name' => 'pdf_generation_zip',
                'description' => 'Generate multiple PDFs and ZIP them',
                'complexity' => 'O(orders * items)',
                'scenarios' => null,
            ],
        ];
    }
}
