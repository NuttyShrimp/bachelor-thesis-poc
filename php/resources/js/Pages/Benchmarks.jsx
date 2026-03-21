import { Head } from '@inertiajs/react';
import { useState, useEffect } from 'react';

/**
 * Format milliseconds nicely
 */
const formatMs = (ms) => {
    if (ms === undefined || ms === null) return '-';
    if (ms < 1) return `${(ms * 1000).toFixed(1)}µs`;
    if (ms < 1000) return `${ms.toFixed(2)}ms`;
    return `${(ms / 1000).toFixed(2)}s`;
};

/**
 * Format throughput
 */
const formatThroughput = (value) => {
    if (!value) return '-';
    if (value >= 1000000) return `${(value / 1000000).toFixed(1)}M/s`;
    if (value >= 1000) return `${(value / 1000).toFixed(1)}K/s`;
    return `${value.toFixed(0)}/s`;
};

/**
 * Get color class based on performance
 */
const getPerformanceColor = (ms) => {
    if (ms < 1) return 'text-green-400';
    if (ms < 10) return 'text-green-300';
    if (ms < 50) return 'text-yellow-300';
    if (ms < 100) return 'text-orange-300';
    return 'text-red-300';
};

/**
 * Single metric card
 */
const MetricCard = ({ label, value, unit, subValue }) => (
    <div className="bg-gray-900 rounded-lg p-3">
        <div className="text-gray-500 text-xs uppercase tracking-wide">{label}</div>
        <div className="text-xl font-bold text-blue-300 mt-1">
            {value}
            {unit && <span className="text-sm text-gray-400 ml-1">{unit}</span>}
        </div>
        {subValue && <div className="text-xs text-gray-500 mt-1">{subValue}</div>}
    </div>
);

/**
 * Benchmark result row for a sub-operation
 */
const BenchmarkRow = ({ name, data }) => {
    if (!data || typeof data !== 'object') return null;

    // Handle various field naming conventions from the API
    const mean = data.avg_time_ms ?? data.mean_ms ?? data.mean ?? data.avg_ms;
    const min = data.min_time_ms ?? data.min_ms ?? data.min;
    const max = data.max_time_ms ?? data.max_ms ?? data.max;
    const stdDev = data.std_dev_ms ?? data.std_dev;
    const iterations = data.iterations ?? data.count;
    const itemsProcessed = data.total_mappings ?? data.item_count ?? data.product_count ?? data.order_count ?? data.pdf_count;
    const totalTime = data.total_time_ms;

    // Calculate throughput if not provided
    let throughput = data.throughput_per_second ?? data.ops_per_second;
    if (!throughput && mean > 0 && itemsProcessed) {
        throughput = (itemsProcessed / mean) * 1000; // items per second
    }

    return (
        <tr className="border-b border-gray-700 hover:bg-gray-800/50">
            <td className="py-3 px-4 font-medium text-gray-200">
                {name.replace(/_/g, ' ')}
            </td>
            <td className={`py-3 px-4 text-right font-mono ${getPerformanceColor(mean)}`}>
                {formatMs(mean)}
            </td>
            <td className="py-3 px-4 text-right font-mono text-gray-400">
                {formatMs(min)}
            </td>
            <td className="py-3 px-4 text-right font-mono text-gray-400">
                {formatMs(max)}
            </td>
            <td className="py-3 px-4 text-right font-mono text-gray-500">
                ±{formatMs(stdDev)}
            </td>
            <td className="py-3 px-4 text-right font-mono text-purple-300">
                {formatThroughput(throughput)}
            </td>
            <td className="py-3 px-4 text-right text-gray-500">
                {iterations ?? '-'}
            </td>
            <td className="py-3 px-4 text-right text-gray-500">
                {itemsProcessed?.toLocaleString() ?? '-'}
            </td>
            <td className="py-3 px-4 text-right font-mono text-yellow-300">
                {formatMs(totalTime)}
            </td>
        </tr>
    );
};

/**
 * Check if data object is a direct benchmark result (has timing fields)
 */
const isDirectResult = (data) => {
    if (!data || typeof data !== 'object') return false;
    return data.avg_time_ms !== undefined ||
           data.mean_ms !== undefined ||
           data.mean !== undefined ||
           data.avg_ms !== undefined ||
           data.operation !== undefined;
};

/**
 * Section for a benchmark category (e.g., dto_mapping, vat_calculation)
 */
const BenchmarkSection = ({ name, data }) => {
    if (!data || typeof data !== 'object') return null;

    // Check if this is a direct result or has nested sub-benchmarks
    const isDirect = isDirectResult(data);

    if (isDirect) {
        // Direct result - single benchmark
        return (
            <div className="mb-6">
                <h3 className="text-lg font-semibold text-blue-400 mb-3 capitalize">
                    {name.replace(/_/g, ' ')}
                </h3>
                <div className="overflow-x-auto">
                    <table className="w-full text-sm">
                        <thead>
                            <tr className="text-gray-400 border-b border-gray-700">
                                <th className="py-2 px-4 text-left">Operation</th>
                                <th className="py-2 px-4 text-right">Mean</th>
                                <th className="py-2 px-4 text-right">Min</th>
                                <th className="py-2 px-4 text-right">Max</th>
                                <th className="py-2 px-4 text-right">Std Dev</th>
                                <th className="py-2 px-4 text-right">Throughput</th>
                                <th className="py-2 px-4 text-right">Iters</th>
                                <th className="py-2 px-4 text-right">Items</th>
                                <th className="py-2 px-4 text-right">Total</th>
                            </tr>
                        </thead>
                        <tbody>
                            <BenchmarkRow name={name} data={data} />
                        </tbody>
                    </table>
                </div>
            </div>
        );
    }

    // Nested structure - has sub-benchmarks
    return (
        <div className="mb-6">
            <h3 className="text-lg font-semibold text-blue-400 mb-3 capitalize">
                {name.replace(/_/g, ' ')}
            </h3>
            <div className="overflow-x-auto">
                <table className="w-full text-sm">
                    <thead>
                        <tr className="text-gray-400 border-b border-gray-700">
                            <th className="py-2 px-4 text-left">Operation</th>
                            <th className="py-2 px-4 text-right">Mean</th>
                            <th className="py-2 px-4 text-right">Min</th>
                            <th className="py-2 px-4 text-right">Max</th>
                            <th className="py-2 px-4 text-right">Std Dev</th>
                            <th className="py-2 px-4 text-right">Throughput</th>
                            <th className="py-2 px-4 text-right">Iters</th>
                            <th className="py-2 px-4 text-right">Items</th>
                            <th className="py-2 px-4 text-right">Total</th>
                        </tr>
                    </thead>
                    <tbody>
                        {Object.entries(data).map(([subName, subData]) => (
                            <BenchmarkRow key={subName} name={subName} data={subData} />
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

/**
 * Main results table component
 */
const BenchmarkResultsTable = ({ data }) => {
    if (!data || typeof data !== 'object') {
        return <div className="text-gray-400">No results to display</div>;
    }

    // Calculate summary stats - extract all mean times from nested structure
    const allMeans = [];
    const extractMeans = (obj) => {
        if (!obj || typeof obj !== 'object') return;
        // Check for timing field (various naming conventions)
        const mean = obj.avg_time_ms ?? obj.mean_ms ?? obj.mean ?? obj.avg_ms;
        if (mean !== undefined) {
            allMeans.push(mean);
        } else {
            // Recurse into nested objects
            Object.values(obj).forEach(extractMeans);
        }
    };
    extractMeans(data);

    const totalMean = allMeans.reduce((a, b) => a + b, 0);
    const avgMean = allMeans.length > 0 ? totalMean / allMeans.length : 0;
    const maxMean = Math.max(...allMeans, 0);
    const minMean = Math.min(...allMeans.filter(m => m > 0), Infinity);

    return (
        <div>
            {/* Summary Cards */}
            {allMeans.length > 1 && (
                <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-6">
                    <MetricCard
                        label="Benchmarks Run"
                        value={allMeans.length}
                    />
                    <MetricCard
                        label="Avg Time"
                        value={formatMs(avgMean)}
                    />
                    <MetricCard
                        label="Fastest"
                        value={formatMs(minMean === Infinity ? 0 : minMean)}
                    />
                    <MetricCard
                        label="Slowest"
                        value={formatMs(maxMean)}
                    />
                </div>
            )}

            {/* Benchmark Sections */}
            {Object.entries(data).map(([name, sectionData]) => (
                <BenchmarkSection key={name} name={name} data={sectionData} />
            ))}
        </div>
    );
};

/**
 * BENCHMARK DASHBOARD
 *
 * React frontend for triggering PHP benchmarks.
 * This simulates how a Swift app would call the same API endpoints.
 *
 * SWIFT EQUIVALENT:
 * ```swift
 * struct BenchmarkView: View {
 *     @State private var results: BenchmarkResults?
 *     @State private var isRunning = false
 *
 *     var body: some View {
 *         VStack {
 *             Button("Run Benchmarks") { runBenchmarks() }
 *             if let results = results {
 *                 BenchmarkResultsView(results: results)
 *             }
 *         }
 *     }
 *
 *     func runBenchmarks() async {
 *         isRunning = true
 *         let url = URL(string: "http://localhost/api/benchmarks/run-all")!
 *         let (data, _) = try await URLSession.shared.data(from: url)
 *         results = try JSONDecoder().decode(BenchmarkResults.self, from: data)
 *         isRunning = false
 *     }
 * }
 * ```
 */
export default function Benchmarks() {
    const [operations, setOperations] = useState([]);
    const [healthStatus, setHealthStatus] = useState(null);
    const [results, setResults] = useState(null);
    const [isRunning, setIsRunning] = useState(false);
    const [currentOperation, setCurrentOperation] = useState('');
    const [error, setError] = useState(null);

    // Load available operations on mount
    useEffect(() => {
        fetchOperations();
        checkHealth();
    }, []);

    const fetchOperations = async () => {
        try {
            const response = await fetch('/api/benchmarks');
            const data = await response.json();
            setOperations(data.operations || []);
        } catch (err) {
            setError('Failed to load operations: ' + err.message);
        }
    };

    const checkHealth = async () => {
        try {
            const response = await fetch('/api/benchmarks/health');
            const data = await response.json();
            setHealthStatus(data);
        } catch (err) {
            setHealthStatus({ status: 'error', message: err.message });
        }
    };

    const runSingleBenchmark = async (operation) => {
        setIsRunning(true);
        setCurrentOperation(operation);
        setError(null);
        setResults(null); // Clear previous results

        try {
            const response = await fetch(`/api/benchmarks/run/${operation}`);
            const data = await response.json();
            setResults({
                benchmarks: {
                    [operation]: data.benchmarks || data.benchmark || data
                },
                meta: data.meta
            });
        } catch (err) {
            setError(`Failed to run ${operation}: ${err.message}`);
        } finally {
            setIsRunning(false);
            setCurrentOperation('');
        }
    };

    const runQuickBenchmark = async () => {
        setIsRunning(true);
        setCurrentOperation('quick');
        setError(null);
        setResults(null); // Clear previous results

        try {
            const response = await fetch('/api/benchmarks/quick');
            const data = await response.json();
            setResults(data);
        } catch (err) {
            setError('Failed to run quick benchmark: ' + err.message);
        } finally {
            setIsRunning(false);
            setCurrentOperation('');
        }
    };

    const runAllBenchmarks = async () => {
        setIsRunning(true);
        setCurrentOperation('all');
        setError(null);
        setResults(null); // Clear previous results

        try {
            const response = await fetch('/api/benchmarks/run-all', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    iterations: 50,
                    excel_iterations: 5,
                    pdf_iterations: 20,
                    pdf_count: 20,
                    zip_iterations: 2
                })
            });
            const data = await response.json();
            setResults(data);
        } catch (err) {
            setError('Failed to run all benchmarks: ' + err.message);
        } finally {
            setIsRunning(false);
            setCurrentOperation('');
        }
    };

    return (
        <>
            <Head title="PHP vs Swift Benchmarks" />

            <div className="min-h-screen bg-gray-900 text-gray-100 p-8">
                <div className="max-w-6xl mx-auto">
                    {/* Header */}
                    <header className="mb-8">
                        <h1 className="text-3xl font-bold text-blue-400">
                            PHP vs Swift Benchmark Suite
                        </h1>
                        <p className="text-gray-400 mt-2">
                            Bachelor Thesis - Performance Comparison Study
                        </p>
                    </header>

                    {/* Health Status */}
                    {healthStatus && (
                        <div className={`p-4 rounded-lg mb-6 ${
                            healthStatus.status === 'ready'
                                ? 'bg-green-900/50 border border-green-700'
                                : 'bg-red-900/50 border border-red-700'
                        }`}>
                            <div className="flex items-center justify-between">
                                <div>
                                    <span className="font-semibold">
                                        Status: {healthStatus.status}
                                    </span>
                                    <span className="text-gray-400 ml-4">
                                        Runtime: {healthStatus.meta?.runtime_mode || 'unknown'}
                                    </span>
                                    <span className="text-gray-400 ml-4">
                                        PHP: {healthStatus.meta?.php_version || 'unknown'}
                                    </span>
                                </div>
                                <button
                                    onClick={checkHealth}
                                    className="text-sm text-blue-400 hover:text-blue-300"
                                >
                                    Refresh
                                </button>
                            </div>
                        </div>
                    )}

                    {/* Error Display */}
                    {error && (
                        <div className="bg-red-900/50 border border-red-700 p-4 rounded-lg mb-6">
                            <p className="text-red-300">{error}</p>
                        </div>
                    )}

                    {/* Action Buttons */}
                    <div className="flex gap-4 mb-8">
                        <button
                            onClick={runQuickBenchmark}
                            disabled={isRunning}
                            className={`px-6 py-3 rounded-lg font-semibold transition ${
                                isRunning
                                    ? 'bg-gray-700 text-gray-500 cursor-not-allowed'
                                    : 'bg-blue-600 hover:bg-blue-500 text-white'
                            }`}
                        >
                            {isRunning && currentOperation === 'quick' ? 'Running...' : 'Quick Benchmark'}
                        </button>

                        <button
                            onClick={runAllBenchmarks}
                            disabled={isRunning}
                            className={`px-6 py-3 rounded-lg font-semibold transition ${
                                isRunning
                                    ? 'bg-gray-700 text-gray-500 cursor-not-allowed'
                                    : 'bg-green-600 hover:bg-green-500 text-white'
                            }`}
                        >
                            {isRunning && currentOperation === 'all' ? 'Running...' : 'Run All Benchmarks'}
                        </button>
                    </div>

                    {/* Operations Grid */}
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-8">
                        {operations.map((op) => (
                            <div
                                key={op.name}
                                className="bg-gray-800 rounded-lg p-4 border border-gray-700"
                            >
                                <h3 className="font-semibold text-lg text-blue-300">
                                    {op.name.replace(/_/g, ' ')}
                                </h3>
                                <p className="text-gray-400 text-sm mt-1">
                                    {op.description}
                                </p>
                                <p className="text-gray-500 text-xs mt-2">
                                    Complexity: {op.complexity}
                                </p>
                                <button
                                    onClick={() => runSingleBenchmark(op.name)}
                                    disabled={isRunning}
                                    className={`mt-3 px-4 py-2 rounded text-sm transition ${
                                        isRunning
                                            ? 'bg-gray-700 text-gray-500 cursor-not-allowed'
                                            : 'bg-gray-700 hover:bg-gray-600 text-white'
                                    }`}
                                >
                                    {isRunning && currentOperation === op.name ? 'Running...' : 'Run'}
                                </button>
                            </div>
                        ))}
                    </div>

                    {/* Results Display */}
                    {results && (
                        <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
                            <h2 className="text-xl font-semibold text-green-400 mb-4">
                                Benchmark Results
                            </h2>

                            {/* Meta info */}
                            {results.meta && (
                                <div className="bg-gray-900 rounded p-4 mb-4">
                                    <h3 className="text-sm font-semibold text-gray-400 mb-2">
                                        Environment
                                    </h3>
                                    <div className="grid grid-cols-2 md:grid-cols-4 gap-2 text-sm">
                                        <div>
                                            <span className="text-gray-500">PHP:</span>{' '}
                                            <span className="text-blue-300">{results.meta.php_version}</span>
                                        </div>
                                        <div>
                                            <span className="text-gray-500">Mode:</span>{' '}
                                            <span className="text-blue-300">{results.meta.runtime_mode}</span>
                                        </div>
                                        <div>
                                            <span className="text-gray-500">OPcache:</span>{' '}
                                            <span className={results.meta.opcache_enabled ? 'text-green-300' : 'text-red-300'}>
                                                {results.meta.opcache_enabled ? 'Enabled' : 'Disabled'}
                                            </span>
                                        </div>
                                        {results.meta.total_benchmark_time_ms && (
                                            <div>
                                                <span className="text-gray-500">Total Time:</span>{' '}
                                                <span className="text-yellow-300">
                                                    {(results.meta.total_benchmark_time_ms / 1000).toFixed(2)}s
                                                </span>
                                            </div>
                                        )}
                                    </div>
                                </div>
                            )}

                            {/* Benchmark Results - Formatted Tables */}
                            <BenchmarkResultsTable data={results.benchmarks || results.benchmark || results} />

                            {/* Raw JSON toggle */}
                            <details className="mt-4">
                                <summary className="text-gray-400 text-sm cursor-pointer hover:text-gray-300">
                                    View Raw JSON
                                </summary>
                                <pre className="bg-gray-900 rounded p-4 overflow-auto max-h-96 text-xs text-gray-300 mt-2">
                                    {JSON.stringify(results.benchmarks || results.benchmark || results, null, 2)}
                                </pre>
                            </details>
                        </div>
                    )}

                    {/* Footer */}
                    <footer className="mt-8 text-center text-gray-500 text-sm">
                        <p>
                            This dashboard triggers the same API endpoints that a Swift application would call.
                        </p>
                        <p className="mt-2">
                            Use <code className="bg-gray-800 px-2 py-1 rounded">php artisan octane:start</code> to test with Laravel Octane (FrankenPHP).
                        </p>
                    </footer>
                </div>
            </div>
        </>
    );
}