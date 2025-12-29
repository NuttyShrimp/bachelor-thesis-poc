# PHP vs Swift Benchmark Project

## Project Overview
Bachelor thesis comparing PHP (Laravel) vs Swift performance for typical web application operations.

## Benchmark Methodology

### How Benchmarks Work
Each benchmark operation runs **multiple iterations** to get statistically meaningful results:

```
Total API Time = Iterations × Mean Time per Iteration + Overhead
```

Example: PDF Generation ZIP
- **Iterations**: 5
- **Mean per iteration**: 5.31s (generate 50 PDFs + zip them)
- **Total time**: ~26.5s

### Metrics Explained
| Metric | Description |
|--------|-------------|
| Mean | Average time per iteration |
| Min/Max | Fastest/slowest iteration |
| Std Dev | Variance between iterations |
| Throughput | Items processed per second |
| Iters | Number of iterations run |
| Items | Items processed per iteration |
| Total | Total time for all iterations |

### Fair Comparison Requirements
For PHP vs Swift comparison to be valid, **both must**:
1. Run the same number of iterations
2. Process the same data (use exported JSON files)
3. Perform identical operations (DTO mapping, PDF generation, etc.)
4. Measure only the operation time (exclude HTTP overhead for CLI benchmarks)

## Setup

### PHP-FPM (Herd default)
- URL: https://swiftbenchmark.test
- Standard PHP-FPM via Laravel Herd

### Laravel Octane + FrankenPHP
- URL: http://127.0.0.1:8888
- Start command: `php artisan octane:start --server=frankenphp --host=127.0.0.1 --port=8888`
- Memory limit: 512M (set in `public/frankenphp-worker.php`)

## Benchmark Data (exported from BakerOnline)

Location: `/Users/benserlippens/Herd/bachelorproef/jan/data/`

| File                | Size      | Contents                                              |
|---------------------|-----------|-------------------------------------------------------|
| products.json       | 50.01 MB  | 5,767 products with settings_json, translations_json  |
| orders.json         | 23.1 MB   | 2,326 orders + 3,271 order products + 1,518 options   |
| shop.json           | 997 KB    | Shop with 8 categories                                |
| cart_scenarios.json | 716 KB    | 4 cart scenarios (small, medium, large, xl)           |
| product_prices.json | 207 KB    | 476 product prices                                    |

**Total: ~75 MB of real production data**

### Export Command
```bash
php artisan benchmark:export-data --products=20000 --orders=10000
```
Note: Limited by actual BakerOnline data availability.

## API Endpoints

| Method | Route                          | Description              |
|--------|--------------------------------|--------------------------|
| GET    | /api/benchmarks                | List available operations|
| GET    | /api/benchmarks/health         | Health check             |
| GET    | /api/benchmarks/quick          | Quick/light benchmark    |
| GET    | /api/benchmarks/run/{operation}| Run single benchmark     |
| POST   | /api/benchmarks/run-all        | Run all benchmarks       |

## Benchmark Operations

1. **dto_mapping** - Map JSON to PHP DTOs (product_settings, order_settings, order_products, full_order)
2. **vat_calculation** - Calculate VAT for cart scenarios (small, medium, large, xl)
3. **cart_calculation** - Full cart totals with options
4. **json_transformation** - Transform shop data to API response format
5. **excel_generation** - Generate Excel export of orders
6. **pdf_generation_single** - Generate single PDF
7. **pdf_generation_zip** - Generate ZIP with multiple PDFs

## Frontend Dashboard

- URL: `/benchmarks` (Inertia/React)
- Features:
  - Run individual or all benchmarks
  - Formatted results table with color-coded performance
  - Summary cards (avg, min, max times)
  - Raw JSON toggle

## Key Files

- `app/Benchmarks/BenchmarkRunner.php` - Main benchmark orchestrator
- `app/Benchmarks/Operations/*.php` - Individual benchmark implementations
- `app/Benchmarks/Dtos/*.php` - Data Transfer Objects
- `app/Http/Controllers/BenchmarkController.php` - API controller
- `resources/js/Pages/Benchmarks.jsx` - Frontend dashboard
- `public/frankenphp-worker.php` - Octane worker with memory config

## Performance Notes

- Octane keeps PHP in memory (no cold start per request)
- OPcache stays warm between requests
- Memory limit increased to 512M for PDF generation
- FrankenPHP provides Go-like performance for PHP

---

## Swift Implementation Guide

### Project Structure
```
SwiftBenchmark/
├── Package.swift
├── Sources/
│   ├── App/
│   │   ├── Controllers/
│   │   │   └── BenchmarkController.swift
│   │   ├── Benchmarks/
│   │   │   ├── BenchmarkRunner.swift
│   │   │   ├── DtoMapping.swift
│   │   │   ├── VatCalculation.swift
│   │   │   ├── CartCalculation.swift
│   │   │   ├── JsonTransformation.swift
│   │   │   ├── ExcelGeneration.swift
│   │   │   └── PdfGeneration.swift
│   │   ├── DTOs/
│   │   │   ├── ProductSettings.swift
│   │   │   └── OrderSettings.swift
│   │   └── routes.swift
│   └── Run/
│       └── main.swift
└── data/  (symlink to PHP project's data folder)
```

### Benchmark Runner (Swift)
```swift
import Foundation

struct BenchmarkResult: Codable {
    let operation: String
    let iterations: Int
    let avgTimeMs: Double
    let minTimeMs: Double
    let maxTimeMs: Double
    let stdDevMs: Double
    let totalTimeMs: Double
    let itemCount: Int?

    enum CodingKeys: String, CodingKey {
        case operation
        case iterations
        case avgTimeMs = "avg_time_ms"
        case minTimeMs = "min_time_ms"
        case maxTimeMs = "max_time_ms"
        case stdDevMs = "std_dev_ms"
        case totalTimeMs = "total_time_ms"
        case itemCount = "item_count"
    }
}

struct BenchmarkRunner {

    /// Run a benchmark with multiple iterations (MUST match PHP iterations!)
    static func benchmark<T>(
        name: String,
        iterations: Int,
        itemCount: Int? = nil,
        operation: () throws -> T
    ) -> BenchmarkResult {
        var times: [Double] = []

        for _ in 0..<iterations {
            let start = DispatchTime.now()
            _ = try? operation()
            let end = DispatchTime.now()

            let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
            let timeMs = Double(nanoTime) / 1_000_000
            times.append(timeMs)
        }

        let mean = times.reduce(0, +) / Double(times.count)
        let minTime = times.min() ?? 0
        let maxTime = times.max() ?? 0
        let total = times.reduce(0, +)

        // Standard deviation
        let squaredDiffs = times.map { pow($0 - mean, 2) }
        let variance = squaredDiffs.reduce(0, +) / Double(times.count)
        let stdDev = sqrt(variance)

        return BenchmarkResult(
            operation: name,
            iterations: iterations,
            avgTimeMs: mean,
            minTimeMs: minTime,
            maxTimeMs: maxTime,
            stdDevMs: stdDev,
            totalTimeMs: total,
            itemCount: itemCount
        )
    }
}
```

### DTO Mapping Example (Swift)
```swift
import Foundation

// Must match PHP's ProductSettingsData structure
struct ProductSettings: Codable {
    let seo: SeoData?
    let photo: String?
    let price: PriceSettings?
    let stock: StockSettings?
    let photos: [String]?
    let photosFsItems: PhotosFsData?
    let maxOrderAmount: Int?
    let minOrderAmount: Int?
    let nutrients: NutrientsData?

    enum CodingKeys: String, CodingKey {
        case seo, photo, price, stock, photos
        case photosFsItems = "photos_fs"
        case maxOrderAmount, minOrderAmount
        case nutrients
    }
}

struct SeoData: Codable {
    let url: [String: String]?
    let title: [String: String]?
    let description: [String: String]?
}

// ... other DTOs

struct DtoMappingBenchmark {
    static func benchmarkProductSettings(iterations: Int = 50) -> BenchmarkResult {
        // Load products.json (same data as PHP)
        let url = URL(fileURLWithPath: "data/products.json")
        let data = try! Data(contentsOf: url)
        let json = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
        let products = json["products"] as! [[String: Any]]

        return BenchmarkRunner.benchmark(
            name: "dto_mapping_product_settings",
            iterations: iterations,
            itemCount: products.count
        ) {
            // Map each product's settings_json to ProductSettings DTO
            for product in products {
                if let settingsJson = product["settings_json"] as? [String: Any] {
                    let settingsData = try! JSONSerialization.data(withJSONObject: settingsJson)
                    _ = try! JSONDecoder().decode(ProductSettings.self, from: settingsData)
                }
            }
        }
    }
}
```

### PDF Generation Example (Swift)
```swift
import Foundation
// Using a PDF library like TPPDF or similar

struct PdfGenerationBenchmark {

    /// Generate ZIP with multiple PDFs - MUST use same iterations as PHP!
    static func benchmarkZip(pdfCount: Int = 50, iterations: Int = 5) -> BenchmarkResult {
        return BenchmarkRunner.benchmark(
            name: "pdf_generation_zip",
            iterations: iterations,  // Same as PHP!
            itemCount: pdfCount
        ) {
            // Create temp directory
            let tempDir = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
            try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

            // Generate PDFs
            for i in 0..<pdfCount {
                let pdfData = generateInvoicePdf(orderIndex: i)
                let pdfPath = tempDir.appendingPathComponent("invoice_\(i).pdf")
                try! pdfData.write(to: pdfPath)
            }

            // Create ZIP
            let zipPath = tempDir.appendingPathComponent("invoices.zip")
            try! createZip(from: tempDir, to: zipPath)

            // Cleanup
            try? FileManager.default.removeItem(at: tempDir)
        }
    }

    private static func generateInvoicePdf(orderIndex: Int) -> Data {
        // Use TPPDF or similar library
        // Match PHP's DomPDF output as closely as possible
        fatalError("Implement with actual PDF library")
    }
}
```

### Vapor Routes (Swift HTTP API)
```swift
import Vapor

func routes(_ app: Application) throws {
    let benchmarks = app.grouped("api", "benchmarks")

    // Health check
    benchmarks.get("health") { req -> [String: String] in
        return [
            "status": "ready",
            "runtime": "Swift",
            "version": "5.9"
        ]
    }

    // Run single benchmark
    benchmarks.get("run", ":operation") { req -> BenchmarkResult in
        let operation = req.parameters.get("operation")!
        let iterations = req.query[Int.self, at: "iterations"] ?? 50

        switch operation {
        case "dto_mapping":
            return DtoMappingBenchmark.benchmarkProductSettings(iterations: iterations)
        case "pdf_generation_zip":
            let pdfCount = req.query[Int.self, at: "pdf_count"] ?? 50
            return PdfGenerationBenchmark.benchmarkZip(pdfCount: pdfCount, iterations: 5)
        default:
            throw Abort(.badRequest, reason: "Unknown operation: \(operation)")
        }
    }

    // Run all benchmarks
    benchmarks.post("run-all") { req -> BenchmarkResults in
        let startTime = DispatchTime.now()

        var results: [String: Any] = [:]

        // DTO Mapping - 50 iterations (same as PHP!)
        results["dto_mapping"] = [
            "product_settings": DtoMappingBenchmark.benchmarkProductSettings(iterations: 50),
            "order_settings": DtoMappingBenchmark.benchmarkOrderSettings(iterations: 50),
            // ...
        ]

        // PDF Generation ZIP - 5 iterations, 50 PDFs (same as PHP!)
        results["pdf_generation_zip"] = PdfGenerationBenchmark.benchmarkZip(
            pdfCount: 50,
            iterations: 5
        )

        let endTime = DispatchTime.now()
        let totalMs = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000

        return BenchmarkResults(
            meta: BenchmarkMeta(
                runtime: "Swift",
                version: "5.9",
                totalBenchmarkTimeMs: totalMs
            ),
            benchmarks: results
        )
    }
}
```

### Key Points for Fair Comparison

1. **Same Iterations**: PHP runs 5 iterations for PDF ZIP → Swift must also run 5
2. **Same Data**: Both load from `data/products.json`, `data/orders.json`, etc.
3. **Same Output Format**: JSON response structure must match for dashboard compatibility
4. **Timing Method**:
   - PHP: `hrtime(true)` (nanoseconds)
   - Swift: `DispatchTime.now().uptimeNanoseconds`
5. **Warm-up**: Consider running 1-2 warm-up iterations before measuring (both languages)

### Running Swift Benchmarks

```bash
# Build release mode for accurate benchmarks
swift build -c release

# Run server
.build/release/Run serve --hostname 127.0.0.1 --port 8080

# Test endpoint
curl http://127.0.0.1:8080/api/benchmarks/run/dto_mapping
```

### Comparing Results

The dashboard at `/benchmarks` can be configured to call either:
- PHP: `http://127.0.0.1:8888/api/benchmarks/...`
- Swift: `http://127.0.0.1:8080/api/benchmarks/...`

Or create a comparison view that calls both and shows results side-by-side.