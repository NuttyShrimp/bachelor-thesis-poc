<?php

namespace App\Benchmarks\Operations;

use App\Benchmarks\DataLoader;
use Barryvdh\DomPDF\Facade\Pdf;

/**
 * PDF GENERATION BENCHMARK
 *
 * Generates PDF invoices from order data.
 * Simulates GenerateInvoicePdfAction and GenerateZipWithInvoicesAction.
 *
 * ALGORITHM:
 * 1. Load order data with products/options
 * 2. Render HTML template (simulate Blade view)
 * 3. Convert HTML to PDF using DomPDF
 * 4. Return PDF binary
 *
 * This is VERY expensive because:
 * - HTML parsing is CPU-intensive
 * - CSS processing for each element
 * - Font rendering and text layout
 * - Image embedding (if any)
 *
 * SWIFT IMPLEMENTATION NOTES:
 * ===========================
 * - TPPDF library for native PDF generation (no HTML step!)
 * - PDFKit on macOS/iOS for system-level rendering
 * - Direct PDF generation is 5-10x faster than HTML→PDF
 * - Consider using templates with variable substitution
 *
 * Example Swift with TPPDF:
 * ```swift
 * import TPPDF
 *
 * func generateInvoice(for order: Order) throws -> Data {
 *     let document = PDFDocument(format: .a4)
 *
 *     // Header
 *     document.add(text: "Invoice #\(order.id)")
 *     document.add(space: 20)
 *
 *     // Table header
 *     let table = PDFTable(rows: order.products.count + 1, columns: 5)
 *     table[0, 0].content = "Product".asTableContent
 *     table[0, 1].content = "Qty".asTableContent
 *     table[0, 2].content = "Price".asTableContent
 *     table[0, 3].content = "VAT".asTableContent
 *     table[0, 4].content = "Total".asTableContent
 *
 *     // Table data
 *     for (index, product) in order.products.enumerated() {
 *         let row = index + 1
 *         table[row, 0].content = product.name.asTableContent
 *         table[row, 1].content = "\(product.quantity)".asTableContent
 *         table[row, 2].content = formatPrice(product.unitPrice).asTableContent
 *         table[row, 3].content = "\(product.vatRate)%".asTableContent
 *         table[row, 4].content = formatPrice(product.lineTotal).asTableContent
 *     }
 *
 *     document.add(table: table)
 *
 *     // Totals
 *     document.add(space: 20)
 *     document.add(text: "Total: \(formatPrice(order.total))", style: .bold)
 *
 *     // Generate PDF data
 *     let generator = PDFGenerator(document: document)
 *     return try generator.generateData()
 * }
 * ```
 *
 * COMPLEXITY: O(n) where n = order items, but with HIGH constant factor
 */
class PdfGeneration
{
    /**
     * Generate single invoice PDF
     *
     * @param array $order Order data with products
     * @return string PDF content as string
     */
    public static function generateInvoice(array $order): string
    {
        $html = self::renderInvoiceHtml($order);

        $pdf = Pdf::loadHTML($html);
        $pdf->setPaper('a4');

        return $pdf->output();
    }

    /**
     * Render invoice HTML
     * In production this would use Blade templates
     */
    public static function renderInvoiceHtml(array $order): string
    {
        $products = $order['products'] ?? [];
        $subtotal = 0;
        $vatTotal = 0;

        $itemsHtml = '';
        foreach ($products as $item) {
            $lineTotal = ($item['quantity'] ?? 1) * ($item['unit_price'] ?? 0);
            $lineVat = $lineTotal * (($item['vat_rate'] ?? 21) / 100);
            $subtotal += $lineTotal;
            $vatTotal += $lineVat;

            $optionsHtml = '';
            if (!empty($item['options'])) {
                $optionNames = array_map(fn($o) => $o['name'] ?? '', $item['options']);
                $optionsHtml = '<br><small style="color: #666;">' . implode(', ', $optionNames) . '</small>';
            }

            $itemsHtml .= sprintf(
                '<tr>
                    <td>%s%s</td>
                    <td style="text-align: center;">%d</td>
                    <td style="text-align: right;">€%.2f</td>
                    <td style="text-align: center;">%d%%</td>
                    <td style="text-align: right;">€%.2f</td>
                </tr>',
                htmlspecialchars($item['name'] ?? 'Product'),
                $optionsHtml,
                $item['quantity'] ?? 1,
                $item['unit_price'] ?? 0,
                $item['vat_rate'] ?? 21,
                $lineTotal
            );
        }

        $total = $subtotal + $vatTotal;
        $orderId = $order['id'] ?? 'N/A';
        $orderDate = $order['created_at'] ?? date('Y-m-d H:i:s');

        return <<<HTML
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Invoice #{$orderId}</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'DejaVu Sans', Arial, sans-serif;
            font-size: 11px;
            line-height: 1.4;
            color: #333;
            padding: 40px;
        }
        .header {
            border-bottom: 2px solid #4472C4;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }
        .header h1 {
            color: #4472C4;
            font-size: 28px;
            margin-bottom: 5px;
        }
        .invoice-info {
            display: flex;
            justify-content: space-between;
            margin-bottom: 30px;
        }
        .invoice-info div {
            width: 48%;
        }
        .invoice-info h3 {
            color: #4472C4;
            margin-bottom: 10px;
            font-size: 14px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th {
            background-color: #4472C4;
            color: white;
            padding: 12px 8px;
            text-align: left;
            font-weight: bold;
        }
        td {
            border-bottom: 1px solid #ddd;
            padding: 10px 8px;
            vertical-align: top;
        }
        tr:nth-child(even) {
            background-color: #f8f9fa;
        }
        .totals {
            margin-top: 30px;
            text-align: right;
        }
        .totals table {
            width: 300px;
            margin-left: auto;
        }
        .totals td {
            padding: 8px;
            border: none;
        }
        .totals .label {
            text-align: right;
            color: #666;
        }
        .totals .value {
            text-align: right;
            font-weight: bold;
        }
        .totals .grand-total {
            font-size: 16px;
            color: #4472C4;
            border-top: 2px solid #4472C4;
        }
        .footer {
            position: fixed;
            bottom: 40px;
            left: 40px;
            right: 40px;
            text-align: center;
            color: #666;
            font-size: 10px;
            border-top: 1px solid #ddd;
            padding-top: 15px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>INVOICE</h1>
        <p>Invoice Number: <strong>#{$orderId}</strong></p>
        <p>Date: {$orderDate}</p>
    </div>

    <table>
        <thead>
            <tr>
                <th style="width: 40%;">Product</th>
                <th style="width: 10%; text-align: center;">Qty</th>
                <th style="width: 15%; text-align: right;">Unit Price</th>
                <th style="width: 10%; text-align: center;">VAT</th>
                <th style="width: 15%; text-align: right;">Total</th>
            </tr>
        </thead>
        <tbody>
            {$itemsHtml}
        </tbody>
    </table>

    <div class="totals">
        <table>
            <tr>
                <td class="label">Subtotal:</td>
                <td class="value">€{$subtotal}</td>
            </tr>
            <tr>
                <td class="label">VAT:</td>
                <td class="value">€{$vatTotal}</td>
            </tr>
            <tr class="grand-total">
                <td class="label">Total:</td>
                <td class="value">€{$total}</td>
            </tr>
        </table>
    </div>

    <div class="footer">
        <p>Thank you for your business!</p>
        <p>This is a computer-generated invoice for benchmark testing purposes.</p>
    </div>
</body>
</html>
HTML;
    }

    /**
     * Generate multiple PDFs and ZIP them
     * Simulates GenerateZipWithInvoicesAction
     */
    public static function generateInvoiceZip(array $ordersData, int $limit = 100): string
    {
        $zipPath = storage_path('benchmarks/invoices_' . time() . '_' . rand(1000, 9999) . '.zip');

        // Ensure directory exists
        if (!is_dir(dirname($zipPath))) {
            mkdir(dirname($zipPath), 0755, true);
        }

        $zip = new \ZipArchive();
        $zip->open($zipPath, \ZipArchive::CREATE);

        $count = 0;
        foreach ($ordersData['orders'] ?? [] as $order) {
            if ($count >= $limit) break;

            // Build order with products
            $orderProducts = array_values(array_filter(
                $ordersData['order_products'] ?? [],
                fn($p) => ($p['order_id'] ?? 0) == ($order['id'] ?? 0)
            ));

            // Add options to products
            foreach ($orderProducts as &$product) {
                $product['options'] = array_values(array_filter(
                    $ordersData['order_product_options'] ?? [],
                    fn($o) => ($o['order_product_id'] ?? 0) == ($product['id'] ?? 0)
                ));
            }

            $orderData = array_merge($order, ['products' => $orderProducts]);

            $pdf = self::generateInvoice($orderData);
            $zip->addFromString("invoice_{$order['id']}.pdf", $pdf);

            $count++;
        }

        $zip->close();

        return $zipPath;
    }

    /**
     * Run benchmark - single PDF generation
     */
    public static function benchmarkSingle(int $iterations = 100): array
    {
        $orders = DataLoader::orders();
        $order = $orders['orders'][0] ?? ['id' => 1, 'products' => []];

        // Add products to order
        $orderProducts = array_values(array_filter(
            $orders['order_products'] ?? [],
            fn($p) => ($p['order_id'] ?? 0) == ($order['id'] ?? 0)
        ));

        // Add options to products
        foreach ($orderProducts as &$product) {
            $product['options'] = array_values(array_filter(
                $orders['order_product_options'] ?? [],
                fn($o) => ($o['order_product_id'] ?? 0) == ($product['id'] ?? 0)
            ));
        }

        $order['products'] = $orderProducts;

        // If no products, create mock data
        if (empty($order['products'])) {
            $order['products'] = self::createMockProducts(10);
        }

        // Warm up
        self::generateInvoice($order);

        $times = [];
        $pdfSizes = [];
        $memoryStart = memory_get_usage(true);

        for ($i = 0; $i < $iterations; $i++) {
            $start = hrtime(true);

            $pdf = self::generateInvoice($order);

            $end = hrtime(true);
            $times[] = ($end - $start) / 1_000_000;
            $pdfSizes[] = strlen($pdf);
        }

        $memoryEnd = memory_get_usage(true);

        sort($times);

        return [
            'operation' => 'pdf_generation_single',
            'product_count' => count($order['products']),
            'iterations' => $iterations,
            'avg_time_ms' => round(array_sum($times) / count($times), 3),
            'min_time_ms' => round(min($times), 3),
            'max_time_ms' => round(max($times), 3),
            'std_dev_ms' => round(self::standardDeviation($times), 3),
            'p25_time_ms' => round($times[(int)(count($times) * 0.25)], 3),
            'p50_time_ms' => round($times[(int)(count($times) * 0.50)], 3),
            'p75_time_ms' => round($times[(int)(count($times) * 0.75)], 3),
            'p95_time_ms' => round($times[(int)(count($times) * 0.95)], 3),
            'p99_time_ms' => round($times[(int)(count($times) * 0.99)], 3),
            'memory_used_mb' => round(($memoryEnd - $memoryStart) / 1024 / 1024, 2),
            'avg_pdf_size_kb' => round(array_sum($pdfSizes) / count($pdfSizes) / 1024, 2),
            'total_time_ms' => round(array_sum($times), 3),
        ];
    }

    /**
     * Run benchmark - ZIP with multiple PDFs
     */
    public static function benchmarkZip(int $pdfCount = 50, int $iterations = 5): array
    {
        $orders = DataLoader::orders();

        // Ensure output directory exists
        if (!is_dir(storage_path('benchmarks'))) {
            mkdir(storage_path('benchmarks'), 0755, true);
        }

        $times = [];
        $zipSizes = [];
        $memoryStart = memory_get_usage(true);

        for ($i = 0; $i < $iterations; $i++) {
            $start = hrtime(true);

            $zipFile = self::generateInvoiceZip($orders, $pdfCount);

            $end = hrtime(true);
            $times[] = ($end - $start) / 1_000_000;

            // Capture file size before cleanup
            if (file_exists($zipFile)) {
                $zipSizes[] = filesize($zipFile);
                unlink($zipFile);
            }

            gc_collect_cycles();
        }

        $memoryEnd = memory_get_usage(true);

        sort($times);

        return [
            'operation' => 'pdf_generation_zip',
            'pdf_count' => $pdfCount,
            'iterations' => $iterations,
            'avg_time_ms' => round(array_sum($times) / count($times), 3),
            'min_time_ms' => round(min($times), 3),
            'max_time_ms' => round(max($times), 3),
            'std_dev_ms' => round(self::standardDeviation($times), 3),
            'p25_time_ms' => round($times[(int)(count($times) * 0.25)], 3),
            'p50_time_ms' => round($times[(int)(count($times) * 0.50)], 3),
            'p75_time_ms' => round($times[(int)(count($times) * 0.75)], 3),
            'p95_time_ms' => round($times[(int)(count($times) * 0.95)] ?? end($times), 3),
            'memory_used_mb' => round(($memoryEnd - $memoryStart) / 1024 / 1024, 2),
            'avg_zip_size_kb' => round(array_sum($zipSizes) / max(count($zipSizes), 1) / 1024, 2),
            'total_time_ms' => round(array_sum($times), 3),
        ];
    }

    /**
     * Create mock products for testing
     */
    private static function createMockProducts(int $count): array
    {
        $products = [];
        $vatRates = [6, 12, 21];

        for ($i = 0; $i < $count; $i++) {
            $products[] = [
                'id' => $i + 1,
                'name' => "Product " . ($i + 1),
                'quantity' => rand(1, 5),
                'unit_price' => rand(100, 5000) / 100,
                'vat_rate' => $vatRates[array_rand($vatRates)],
                'options' => self::createMockOptions(rand(0, 3)),
            ];
        }

        return $products;
    }

    private static function createMockOptions(int $count): array
    {
        $options = [];
        for ($i = 0; $i < $count; $i++) {
            $options[] = [
                'id' => $i + 1,
                'name' => "Option " . ($i + 1),
                'price' => rand(0, 500) / 100,
            ];
        }
        return $options;
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
