<?php

namespace App\Benchmarks\Operations;

use App\Benchmarks\DataLoader;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Style\Border;
use PhpOffice\PhpSpreadsheet\Style\Alignment;

/**
 * EXCEL GENERATION BENCHMARK
 *
 * Generates Excel files with order/product data.
 * Simulates GetProductionListExcelWriterAction from production.
 *
 * ALGORITHM (Production List Style):
 * 1. Group orders by date
 * 2. For each date, group by product category
 * 3. For each category, list products
 * 4. For each product, list options/variations
 * 5. Sum quantities across orders
 * 6. Apply styling (headers, borders, colors)
 *
 * This is one of the MOST EXPENSIVE operations due to:
 * - O(n^4) nested loops in production
 * - PhpSpreadsheet object allocation per cell
 * - Styling operations (borders, colors) are slow
 *
 * SWIFT IMPLEMENTATION NOTES:
 * ===========================
 * - Use xlsxwriter library (C-based, very fast)
 * - Or CoreXLSX for reading, custom XML generation for writing
 * - Consider generating CSV for pure speed comparison
 * - Styling is expensive in any language - measure with/without
 *
 * Example Swift with xlsxwriter:
 * ```swift
 * import xlsxwriter
 *
 * func generateProductionList(_ orders: [Order]) throws -> URL {
 *     let outputPath = FileManager.default.temporaryDirectory
 *         .appendingPathComponent("production_list.xlsx")
 *
 *     let workbook = Workbook(filename: outputPath.path)
 *     let worksheet = workbook.addWorksheet(name: "Production List")
 *
 *     // Header format
 *     let headerFormat = workbook.addFormat()
 *     headerFormat.setBold()
 *     headerFormat.setBackgroundColor(0xCCCCCC)
 *
 *     // Headers
 *     let headers = ["Date", "Category", "Product", "Options", "Quantity"]
 *     for (col, header) in headers.enumerated() {
 *         worksheet.write(string: header, row: 0, col: col, format: headerFormat)
 *     }
 *
 *     // Data rows
 *     var row = 1
 *     let grouped = groupOrdersByDateAndProduct(orders)
 *
 *     for (date, categories) in grouped {
 *         for (category, products) in categories {
 *             for (product, variations) in products {
 *                 for variation in variations {
 *                     worksheet.write(string: date, row: row, col: 0)
 *                     worksheet.write(string: category, row: row, col: 1)
 *                     worksheet.write(string: product, row: row, col: 2)
 *                     worksheet.write(string: variation.options, row: row, col: 3)
 *                     worksheet.write(number: Double(variation.quantity), row: row, col: 4)
 *                     row += 1
 *                 }
 *             }
 *         }
 *     }
 *
 *     workbook.close()
 *     return outputPath
 * }
 * ```
 *
 * COMPLEXITY: O(d * c * p * o) - dates * categories * products * options
 */
class ExcelGeneration
{
    /**
     * Generate production list Excel file
     *
     * @param array $ordersData Orders with products and options
     * @return string Path to generated file
     */
    public static function generateProductionList(array $ordersData): string
    {
        $spreadsheet = new Spreadsheet();
        $sheet = $spreadsheet->getActiveSheet();
        $sheet->setTitle('Production List');

        // Group data by date and product
        $grouped = self::groupOrdersByDateAndProduct($ordersData);

        $row = 1;

        // Header row
        $headers = ['Date', 'Category', 'Product', 'Options', 'Quantity', 'Notes'];
        foreach ($headers as $col => $header) {
            $cell = chr(65 + $col) . $row;
            $sheet->setCellValue($cell, $header);

            // Style header
            $sheet->getStyle($cell)->getFont()->setBold(true);
            $sheet->getStyle($cell)->getFill()
                ->setFillType(Fill::FILL_SOLID)
                ->getStartColor()->setRGB('4472C4');
            $sheet->getStyle($cell)->getFont()->getColor()->setRGB('FFFFFF');
            $sheet->getStyle($cell)->getAlignment()
                ->setHorizontal(Alignment::HORIZONTAL_CENTER);
        }
        $row++;

        // Data rows
        $rowCount = 0;
        foreach ($grouped as $date => $categories) {
            foreach ($categories as $category => $products) {
                foreach ($products as $productName => $variations) {
                    foreach ($variations as $variation) {
                        $sheet->setCellValue("A{$row}", $date);
                        $sheet->setCellValue("B{$row}", $category);
                        $sheet->setCellValue("C{$row}", $productName);
                        $sheet->setCellValue("D{$row}", $variation['options']);
                        $sheet->setCellValue("E{$row}", $variation['quantity']);
                        $sheet->setCellValue("F{$row}", '');

                        // Add border to all cells in row
                        $sheet->getStyle("A{$row}:F{$row}")->getBorders()
                            ->getAllBorders()
                            ->setBorderStyle(Border::BORDER_THIN);

                        // Alternate row coloring
                        if ($rowCount % 2 === 1) {
                            $sheet->getStyle("A{$row}:F{$row}")->getFill()
                                ->setFillType(Fill::FILL_SOLID)
                                ->getStartColor()->setRGB('E8E8E8');
                        }

                        $row++;
                        $rowCount++;
                    }
                }
            }
        }

        // Auto-size columns
        foreach (range('A', 'F') as $col) {
            $sheet->getColumnDimension($col)->setAutoSize(true);
        }

        // Freeze header row
        $sheet->freezePane('A2');

        // Save to temp file
        $filename = storage_path('benchmarks/production_list_' . time() . '_' . rand(1000, 9999) . '.xlsx');

        // Ensure directory exists
        if (!is_dir(dirname($filename))) {
            mkdir(dirname($filename), 0755, true);
        }

        $writer = new Xlsx($spreadsheet);
        $writer->save($filename);

        // Clean up memory
        $spreadsheet->disconnectWorksheets();
        unset($spreadsheet);

        return $filename;
    }

    /**
     * Group orders by date and product
     * This simulates the nested grouping in production
     */
    private static function groupOrdersByDateAndProduct(array $ordersData): array
    {
        $grouped = [];

        foreach ($ordersData['orders'] ?? [] as $order) {
            $date = substr($order['created_at'] ?? date('Y-m-d'), 0, 10);

            // Find products for this order
            $orderProducts = array_filter(
                $ordersData['order_products'] ?? [],
                fn($p) => ($p['order_id'] ?? 0) == ($order['id'] ?? 0)
            );

            foreach ($orderProducts as $product) {
                $category = $product['category'] ?? 'Uncategorized';
                $productName = $product['name'] ?? 'Unknown Product';

                // Find options for this product
                $options = array_filter(
                    $ordersData['order_product_options'] ?? [],
                    fn($o) => ($o['order_product_id'] ?? 0) == ($product['id'] ?? 0)
                );

                $optionString = implode(', ', array_map(
                    fn($o) => $o['name'] ?? '',
                    $options
                ));

                // Build nested structure
                if (!isset($grouped[$date])) {
                    $grouped[$date] = [];
                }
                if (!isset($grouped[$date][$category])) {
                    $grouped[$date][$category] = [];
                }
                if (!isset($grouped[$date][$category][$productName])) {
                    $grouped[$date][$category][$productName] = [];
                }

                $key = $optionString ?: 'no_options';
                if (!isset($grouped[$date][$category][$productName][$key])) {
                    $grouped[$date][$category][$productName][$key] = [
                        'options' => $optionString ?: '-',
                        'quantity' => 0,
                    ];
                }

                $grouped[$date][$category][$productName][$key]['quantity'] +=
                    $product['quantity'] ?? 1;
            }
        }

        return $grouped;
    }

    /**
     * Run benchmark
     *
     * @param int $iterations Number of files to generate (default 10, as this is slow)
     * @return array Benchmark results
     */
    public static function benchmark(int $iterations = 10): array
    {
        $orders = DataLoader::orders();

        // Ensure output directory exists
        $outputDir = storage_path('benchmarks');
        if (!is_dir($outputDir)) {
            mkdir($outputDir, 0755, true);
        }

        // Warm up
        $warmupFile = self::generateProductionList($orders);
        if (file_exists($warmupFile)) {
            unlink($warmupFile);
        }

        $times = [];
        $fileSizes = [];
        $memoryStart = memory_get_usage(true);
        $totalStart = time();

        for ($i = 0; $i < $iterations; $i++) {
            $start = hrtime(true);

            $file = self::generateProductionList($orders);

            $end = hrtime(true);
            $times[] = ($end - $start) / 1_000_000;

            // Capture file size before cleanup
            if (file_exists($file)) {
                $fileSizes[] = filesize($file);
                unlink($file);
            }

            // Force garbage collection between iterations
            gc_collect_cycles();
        }

        $totalEnd = time();
        $memoryEnd = memory_get_usage(true);

        sort($times);

        $orderCount = count($orders['orders'] ?? []);
        $productCount = count($orders['order_products'] ?? []);

        return [
            'operation' => 'excel_generation',
            'order_count' => $orderCount,
            'product_count' => $productCount,
            'iterations' => $iterations,
            'start_time_ms' => $totalStart,
            'end_time_ms' => $totalEnd,
            'avg_time_ms' => round(array_sum($times) / count($times), 3),
            'min_time_ms' => round(min($times), 3),
            'max_time_ms' => round(max($times), 3),
            'std_dev_ms' => round(self::standardDeviation($times), 3),
            'p25_time_ms' => round($times[(int)(count($times) * 0.25)], 3),
            'p50_time_ms' => round($times[(int)(count($times) * 0.50)], 3),
            'p75_time_ms' => round($times[(int)(count($times) * 0.75)], 3),
            'p95_time_ms' => round($times[(int)(count($times) * 0.95)] ?? end($times), 3),
            'memory_used_mb' => round(($memoryEnd - $memoryStart) / 1024 / 1024, 2),
            'avg_file_size_kb' => round(array_sum($fileSizes) / max(count($fileSizes), 1) / 1024, 2),
            'total_time_ms' => round(array_sum($times), 3),
        ];
    }

    private static function standardDeviation(array $data): float
    {
        $count = count($data);
        if ($count === 0) return 0;

        $mean = array_sum($data) / $count;
        $squaredDiffs = array_map(fn($x) => pow($x - $mean, 2), $data);

        return sqrt(array_sum($squaredDiffs) / $count);
    }
}
