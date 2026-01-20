<?php

use App\Http\Controllers\BenchmarkController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::get('/health', function (Request $request) {
    return response(null, 200);
});

/*
|--------------------------------------------------------------------------
| Benchmark API Routes
|--------------------------------------------------------------------------
|
| These routes expose the benchmark operations via HTTP API.
| No authentication required - this is a testing/benchmarking tool.
|
| SWIFT NOTE: Create equivalent routes in Vapor:
| ```swift
| let benchmarks = app.grouped("api", "benchmarks")
| benchmarks.get(use: BenchmarkController.index)
| benchmarks.get("run", ":operation", use: BenchmarkController.run)
| benchmarks.post("run-all", use: BenchmarkController.runAll)
| benchmarks.get("quick", use: BenchmarkController.quick)
| benchmarks.get("health", use: BenchmarkController.health)
| ```
|
*/
Route::prefix('benchmarks')->group(function () {
    // List available operations
    Route::get('/', [BenchmarkController::class, 'index']);

    // Health check - verify setup is correct
    Route::get('/health', [BenchmarkController::class, 'health']);

    // Quick benchmark - lighter version for dashboard preview
    Route::get('/quick', [BenchmarkController::class, 'quick']);

    // Run single benchmark
    Route::get('/run/{operation}', [BenchmarkController::class, 'run']);

    // Run all benchmarks (POST because it's a heavy operation)
    Route::post('/run-all', [BenchmarkController::class, 'runAll']);
});
