<?php

namespace App\Benchmarks;

use Laravel\Octane\FrankenPhp\ServerProcessInspector as FrankenPhpServerProcessInspector;
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
        set_time_limit(300);
        $options = array_merge([
            'dto_iterations'   => 50,
            'iterations'       => 100,
            'excel_iterations' => 10,
            'pdf_iterations'   => 50,
            'pdf_count'        => 50,
            'zip_iterations'   => 5,
        ], $options);


        $results = [];

        // DTO Mapping - THE MOST CRITICAL benchmark for PHP vs Swift
        $results['dto_mapping'] = self::run("dto_mapping", $options);
        // VAT Calculation - multiple cart sizes
        $results['vat_calculation'] = [];
        foreach (['small_cart', 'medium_cart', 'large_cart', 'xl_cart'] as $scenario) {
            $results['vat_calculation'][$scenario] = self::run("vat_calculation", array_merge($options, ["scenario" => $scenario]))[$scenario];
        }

        // Cart Calculation - multiple cart sizes
        $results['cart_calculation'] = [];
        foreach (['small_cart', 'medium_cart', 'large_cart', 'xl_cart'] as $scenario) {
            $results["cart_calculation"][$scenario] = self::run("cart_calculation", array_merge($options, ["scenario" => $scenario]))[$scenario];
        }

        // JSON Transformation
        $results['json_transformation'] = self::run("json_transformation", $options);

        // Excel Generation (fewer iterations - it's slow)
        $results['excel_generation'] = self::run("excel_generation", $options);

        // PDF Generation - Single
        $results['pdf_generation_single'] = self::run("pdf_generation_single", $options);

        // PDF Generation - ZIP
        $results['pdf_generation_zip'] = self::run("pdf_generation_zip", $options);

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
        $scenario = $options['scenario'] ?? 'large_cart';
        return match ($operation) {
            'dto_mapping' => DtoMapping::benchmark(
                "all",
                $options['iterations'] ?? 50
            ),
            'vat_calculation' => [
                $scenario => VatCalculation::benchmark(
                    $scenario,
                    $options['iterations'] ?? 100
                )
            ],
            'cart_calculation' => [
                $scenario => CartCalculation::benchmark(
                    $scenario,
                    $options['iterations'] ?? 100
                )
            ],
            'json_transformation' => [
                "json_transformation" => JsonTransformation::benchmark(
                    $options['iterations'] ?? 100
                )
            ],
            'excel_generation' => [
                'excel_generation' => ExcelGeneration::benchmark(
                    $options['iterations'] ?? 10
                )
            ],
            'pdf_generation' => [
                'pdf_generation_single' => PdfGeneration::benchmarkSingle(
                    $options['iterations'] ?? 50
                ),
                "pdf_generation_zip" => PdfGeneration::benchmarkZip(
                    $options['pdf_count'] ?? 50,
                    $options['iterations'] ?? 5
                )
            ],
            default => throw new \InvalidArgumentException("Unknown operation: {$operation}"),
        };
    }

    /**
     * Get system metadata for benchmark context
     */
    public static function getMetadata(): array
    {
        $isOctane = app(FrankenPhpServerProcessInspector::class)
            ->serverIsRunning();

        return [
            'timestamp' => date('c'),
            'php_version' => PHP_VERSION,
            'laravel_version' => app()->version(),
            'runtime' => $isOctane ? 'octane' : 'php-fpm',
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
                'complexity' => 'O(n * d) - records * nested depth',
                'scenarios' => [
                    'dto_mapping_product_settings',
                    'dto_mapping_order_settings',
                    'dto_mapping_order_products',
                    'dto_mapping_full_order',
                ],
            ],
            [
                'name' => 'vat_calculation',
                'complexity' => 'O(n * m) - items * options',
                'scenarios' => ['small_cart', 'medium_cart', 'large_cart', 'xl_cart'],
            ],
            [
                'name' => 'cart_calculation',
                'complexity' => 'O(n * m) - items * options',
                'scenarios' => ['small_cart', 'medium_cart', 'large_cart', 'xl_cart'],
            ],
            [
                'name' => 'json_transformation',
                'complexity' => 'O(c * p) - categories * products',
                'scenarios' => null,
            ],
            [
                'name' => 'excel_generation',
                'complexity' => 'O(d * c * p * o) - dates * categories * products * options',
                'scenarios' => null,
            ],
            [
                'name' => 'pdf_generation_single',
                'complexity' => 'O(n) with high constant factor',
                'scenarios' => null,
            ],
            [
                'name' => 'pdf_generation_zip',
                'complexity' => 'O(orders * items)',
                'scenarios' => null,
            ],
        ];
    }
}
