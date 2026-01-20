<?php

namespace App\Http\Controllers;

use App\Benchmarks\BenchmarkRunner;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * BENCHMARK API CONTROLLER
 *
 * Provides HTTP endpoints for triggering benchmarks.
 * These endpoints can be called from:
 * - React frontend dashboard
 * - cURL commands
 * - Swift HTTP client for comparison
 *
 * SWIFT IMPLEMENTATION NOTES:
 * ===========================
 * Using Vapor framework:
 * ```swift
 * import Vapor
 *
 * func routes(_ app: Application) throws {
 *     let benchmarks = app.grouped("api", "benchmarks")
 *
 *     benchmarks.get { req -> BenchmarkListResponse in
 *         return BenchmarkListResponse(operations: BenchmarkRunner.listOperations())
 *     }
 *
 *     benchmarks.get("run", ":operation") { req -> BenchmarkResult in
 *         let operation = req.parameters.get("operation")!
 *         let iterations = req.query[Int.self, at: "iterations"] ?? 100
 *         return try BenchmarkRunner.run(operation, iterations: iterations)
 *     }
 *
 *     benchmarks.post("run-all") { req -> BenchmarkResults in
 *         return BenchmarkRunner.runAll()
 *     }
 * }
 * ```
 */
class BenchmarkController extends Controller
{
    /**
     * List all available benchmark operations
     *
     * GET /api/benchmarks
     */
    public function index(): JsonResponse
    {
        return response()->json([
            'operations' => BenchmarkRunner::listOperations(),
            'meta' => BenchmarkRunner::getMetadata(),
        ]);
    }

    /**
     * Run a single benchmark operation
     *
     * GET /api/benchmarks/run/{operation}
     *
     * Query params:
     * - iterations: number of iterations (default: 100)
     * - scenario: cart scenario for vat/cart calculations (default: large_cart)
     * - pdf_count: number of PDFs for zip benchmark (default: 50)
     */
    public function run(Request $request, string $operation): JsonResponse
    {
        $validated = $request->validate([
            'iterations' => 'nullable|integer|min:1|max:10000',
            'scenario' => 'nullable|string',
            'pdf_count' => 'nullable|integer|min:1|max:500',
        ]);

        try {
            $startTime = hrtime(true);
            $benchmark = BenchmarkRunner::run($operation, [
                'iterations' => $validated['iterations'] ?? null,
                'scenario' => $validated['scenario'] ?? null,
                'pdf_count' => $validated['pdf_count'] ?? null,
            ]);
            $endTime = hrtime(true);

            $result =[
                'meta' => BenchmarkRunner::getMetadata(),
                'benchmarks' => [
                    $operation => $benchmark
                ],
                'execution_time_ms' => round(($endTime - $startTime) / 1_000_000, 2),
            ];

            return response()->json($result);
        } catch (\InvalidArgumentException $e) {
            return response()->json([
                'error' => $e->getMessage(),
                'available_operations' => array_keys(BenchmarkRunner::OPERATIONS),
            ], 400);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Benchmark failed: ' . $e->getMessage(),
                'trace' => config('app.debug') ? $e->getTraceAsString() : null,
            ], 500);
        }
    }

    /**
     * Run all benchmarks
     *
     * POST /api/benchmarks/run-all
     *
     * Body params (all optional):
     * - iterations: default iterations for most benchmarks (default: 100)
     * - excel_iterations: iterations for Excel (default: 10)
     * - pdf_iterations: iterations for single PDF (default: 50)
     * - pdf_count: PDFs per ZIP (default: 50)
     * - zip_iterations: iterations for ZIP (default: 5)
     */
    public function runAll(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'iterations' => 'nullable|integer|min:1|max:10000',
            'excel_iterations' => 'nullable|integer|min:1|max:100',
            'pdf_iterations' => 'nullable|integer|min:1|max:1000',
            'pdf_count' => 'nullable|integer|min:1|max:500',
            'zip_iterations' => 'nullable|integer|min:1|max:50',
        ]);

        try {
            $startTime = hrtime(true);
            $benchmarks = BenchmarkRunner::runAll(array_filter($validated));
            $endTime = hrtime(true);

            $result = [
                'meta' => BenchmarkRunner::getMetadata(),
                'benchmarks' => $benchmarks,
            ];

            return response()->json($result);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Benchmark suite failed: ' . $e->getMessage(),
                'trace' => config('app.debug') ? $e->getTraceAsString() : null,
            ], 500);
        }
    }

    /**
     * Quick benchmark - runs a lighter version for dashboard preview
     *
     * GET /api/benchmarks/quick
     */
    public function quick(): JsonResponse
    {
        try {
            $startTime = hrtime(true);
            $benchmarks = BenchmarkRunner::runAll([
                'iterations' => 10,
                'excel_iterations' => 2,
                'pdf_iterations' => 5,
                'pdf_count' => 10,
                'zip_iterations' => 1,
            ]);
            $endTime = hrtime(true);

            $result = [
                'meta' => BenchmarkRunner::getMetadata(),
                'benchmarks' => $benchmarks,
            ];
            $result['meta']['total_benchmark_time_ms'] = round(($endTime - $startTime) / 1_000_000, 2);
            $result['meta']['completed_at'] = date('c');

            return response()->json($result);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Quick benchmark failed: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Health check - verify benchmark infrastructure is working
     *
     * GET /api/benchmarks/health
     */
    public function health(): JsonResponse
    {
        $checks = [];

        // Check data files
        $dataPath = base_path('data');
        $checks['data_directory'] = is_dir($dataPath);
        $checks['data_files'] = [
            'orders.json' => file_exists("{$dataPath}/orders.json"),
            'products.json' => file_exists("{$dataPath}/products.json"),
            'shop.json' => file_exists("{$dataPath}/shop.json"),
            'cart_scenarios.json' => file_exists("{$dataPath}/cart_scenarios.json"),
        ];

        // Check storage
        $storagePath = storage_path('benchmarks');
        $checks['storage_writable'] = is_dir($storagePath) || @mkdir($storagePath, 0755, true);

        // Check dependencies
        $checks['dependencies'] = [
            'phpspreadsheet' => class_exists(\PhpOffice\PhpSpreadsheet\Spreadsheet::class),
            'dompdf' => class_exists(\Barryvdh\DomPDF\Facade\Pdf::class),
            'octane' => class_exists(\Laravel\Octane\Octane::class),
        ];

        $allPassed = $checks['data_directory'] &&
                     !in_array(false, $checks['data_files']) &&
                     $checks['storage_writable'] &&
                     $checks['dependencies']['phpspreadsheet'] &&
                     $checks['dependencies']['dompdf'];

        return response()->json([
            'status' => $allPassed ? 'ready' : 'missing_requirements',
            'checks' => $checks,
            'meta' => BenchmarkRunner::getMetadata(),
        ], $allPassed ? 200 : 503);
    }
}
