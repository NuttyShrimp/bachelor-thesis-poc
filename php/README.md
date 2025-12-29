# PHP vs Swift Benchmark Suite

Bachelor Thesis Project - Performance Comparison Study

## Overview

This Laravel application provides a benchmarking suite to compare PHP performance against Swift for typical backend operations. The data is extracted from a real production system (BakerOnline) to ensure realistic complexity.

## Quick Start

```bash
# Navigate to the project
cd ~/Herd/bachelorproef/jan

# Start the development server (using Laravel Herd or Valet)
# Or use the built-in PHP server:
php artisan serve

# Visit the benchmark dashboard
open http://jan.test/benchmarks
# or
open http://localhost:8000/benchmarks
```

## Testing with Laravel Octane (FrankenPHP)

```bash
# Install FrankenPHP runtime
php artisan octane:install --server=frankenphp

# Start Octane server
php artisan octane:start --server=frankenphp

# Now access at http://localhost:8000/benchmarks
# The dashboard will show "octane" as runtime_mode
```

## API Endpoints

All benchmarks are available via REST API:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/benchmarks` | GET | List available operations |
| `/api/benchmarks/health` | GET | Check system health |
| `/api/benchmarks/quick` | GET | Run lightweight benchmarks |
| `/api/benchmarks/run/{operation}` | GET | Run single benchmark |
| `/api/benchmarks/run-all` | POST | Run all benchmarks |

### Example cURL Commands

```bash
# List operations
curl http://localhost:8000/api/benchmarks

# Check health
curl http://localhost:8000/api/benchmarks/health

# Run DTO mapping benchmark (THE MOST IMPORTANT ONE)
curl http://localhost:8000/api/benchmarks/run/dto_mapping

# Run all benchmarks
curl -X POST http://localhost:8000/api/benchmarks/run-all \
  -H "Content-Type: application/json" \
  -d '{"iterations": 50}'
```

## Benchmark Operations

### 1. DTO Mapping (`dto_mapping`) - **CRITICAL**

This is the **MOST IMPORTANT** benchmark for comparing PHP vs Swift. It measures:
- JSON string parsing (`json_decode`)
- Object instantiation from arrays
- Nested object graph creation
- Memory allocation overhead

**PHP Implementation**: `app/Benchmarks/Operations/DtoMapping.php`
**DTOs**: `app/Benchmarks/Dtos/`

**Swift Equivalent**: Use `Codable` protocol with `JSONDecoder`

```swift
struct ProductSettings: Codable {
    let seo: SeoData?
    let price: PriceSettings?
    let stock: StockSettings?
    // ... nested structs
}

func mapProductSettings(from data: Data) throws -> ProductSettings {
    return try JSONDecoder().decode(ProductSettings.self, from: data)
}
```

### 2. VAT Calculation (`vat_calculation`)

Calculates VAT for orders with nested items and options.

**Complexity**: O(n × m) where n = items, m = options per item

**Swift Notes**: Use `Decimal` type for money, not `Float/Double`

### 3. Cart Calculation (`cart_calculation`)

Calculates cart totals with discounts, options, and line items.

**Complexity**: O(n × m)

### 4. JSON Transformation (`json_transformation`)

Transforms shop data to API response format. Simulates transformer/resource classes.

**Complexity**: O(c × p) where c = categories, p = products

### 5. Excel Generation (`excel_generation`)

Generates production list Excel files using PhpSpreadsheet.

**Complexity**: O(d × c × p × o) - dates × categories × products × options

**Swift Options**:
- `xlsxwriter` library (C-based, fast)
- `CoreXLSX` for reading

### 6. PDF Generation (`pdf_generation_single`, `pdf_generation_zip`)

Generates PDF invoices using DomPDF (HTML → PDF conversion).

**Swift Options**:
- TPPDF library (native PDF, no HTML step = faster)
- PDFKit on macOS/iOS

## Data Files

Real production data is stored in `data/`:

| File | Description | Size |
|------|-------------|------|
| `products.json` | 500 products with settings_json, translations_json | ~2.2 MB |
| `orders.json` | 200 orders with products_json, settings_json | ~1.8 MB |
| `shop.json` | Shop with categories and products | ~1 MB |
| `cart_scenarios.json` | 4 cart sizes (small, medium, large, xl) | ~700 KB |
| `product_prices.json` | Product price variants | ~80 KB |

### Data Complexity

The data includes the **full JSON blob complexity** from production:

**Product settings_json**:
- SEO data (per language)
- Photo data with resolutions
- Stock settings
- Price deviations per day
- Nutrients (9+ types)
- Order constraints

**Order settings_json** (48+ nested objects):
- User data
- Delivery/invoice addresses
- Payment processor data (Stripe, Adyen, PayU, SIBS, etc.)
- Loyalty programs (Piggy, Joyn)
- Statistics and metadata

**Order products_json**:
- Product with min/max/warranty
- Product price
- Category reference
- Options array with nested products
- Calculated prices

## Swift Implementation Guide

### Step 1: Create Codable Structs

Look at the DTO files in `app/Benchmarks/Dtos/` and create equivalent Swift structs:

```swift
// ProductSettings.swift
struct ProductSettings: Codable {
    let seo: SeoData?
    let photo: AnyCodable? // Can be String, Array, or null
    let price: PriceSettings?
    let stock: StockSettings?
    let photos: [String]?
    let photos_fs: PhotosFsData?
    let maxOrderAmount: Int?
    let minOrderAmount: Int
    let suggestedOrderWeight: Int
    let nutrients: NutrientsData?
}

struct SeoData: Codable {
    let url: [String: String]
    let title: [String: String]
    let description: [String: String]
}

// ... continue for all nested types
```

### Step 2: Create Benchmark Runner

```swift
struct BenchmarkRunner {
    static func benchmarkDtoMapping(iterations: Int = 50) -> BenchmarkResult {
        let products = loadProducts() // Load from data/products.json
        var times: [Double] = []

        for _ in 0..<iterations {
            let start = DispatchTime.now()

            for product in products {
                let settings = try! JSONDecoder().decode(
                    ProductSettings.self,
                    from: product.settingsJsonData
                )
                // Access nested properties to force full decode
                _ = settings.seo?.title
                _ = settings.photos_fs?.items.count
            }

            let end = DispatchTime.now()
            let nanos = end.uptimeNanoseconds - start.uptimeNanoseconds
            times.append(Double(nanos) / 1_000_000) // ms
        }

        return BenchmarkResult(times: times)
    }
}
```

### Step 3: Create HTTP Server (optional)

Use Vapor or Hummingbird for equivalent API endpoints:

```swift
// Using Vapor
import Vapor

func routes(_ app: Application) throws {
    let benchmarks = app.grouped("api", "benchmarks")

    benchmarks.get { req -> BenchmarkListResponse in
        BenchmarkListResponse(operations: BenchmarkRunner.listOperations())
    }

    benchmarks.get("run", ":operation") { req -> BenchmarkResult in
        let operation = req.parameters.get("operation")!
        return BenchmarkRunner.run(operation)
    }
}
```

## Comparing Results

Run the same benchmarks in both environments and compare:

1. **PHP-FPM Mode**: Normal Laravel request handling
2. **Laravel Octane**: Persistent application state
3. **Swift**: Native compiled binary

Key metrics to compare:
- Average time (ms)
- P95/P99 latency
- Memory usage
- Throughput (requests/second)

## File Structure

```
bachelorproef/jan/
├── app/
│   ├── Benchmarks/
│   │   ├── BenchmarkRunner.php      # Orchestrates all benchmarks
│   │   ├── DataLoader.php           # Loads JSON data files
│   │   ├── Dtos/                    # Data Transfer Objects
│   │   │   ├── ProductSettingsData.php
│   │   │   ├── OrderSettingsData.php
│   │   │   └── OrderProductsData.php
│   │   └── Operations/              # Individual benchmarks
│   │       ├── DtoMapping.php       # ⭐ MOST IMPORTANT
│   │       ├── VatCalculation.php
│   │       ├── CartCalculation.php
│   │       ├── JsonTransformation.php
│   │       ├── ExcelGeneration.php
│   │       └── PdfGeneration.php
│   └── Http/
│       └── Controllers/
│           └── BenchmarkController.php
├── data/                            # Production-like JSON data
│   ├── products.json
│   ├── orders.json
│   ├── shop.json
│   └── cart_scenarios.json
├── resources/
│   └── js/
│       └── Pages/
│           └── Benchmarks.jsx       # React dashboard
└── routes/
    ├── api.php                      # API routes
    └── web.php                      # Web routes
```

## Regenerating Data

If you need fresh data from BakerOnline:

```bash
# From the bakeronline project directory
cd ~/Herd/bakeronline
php artisan benchmark:export-data --products=500 --orders=200
```

This exports real production data to `~/Herd/bachelorproef/jan/data/`.

## Notes

- Each PHP file has Swift implementation hints in the docblocks
- Focus on `dto_mapping` first - it's the core comparison
- The data includes real JSON complexity (not simplified mocks)
- Test both PHP-FPM and Octane modes for fair comparison
# jan
