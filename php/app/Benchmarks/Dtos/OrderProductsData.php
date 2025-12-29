<?php

namespace App\Benchmarks\Dtos;

/**
 * ORDER PRODUCTS DTO
 *
 * Maps the products_json column from orders.
 * This is the HEAVIEST data structure - each order can have many products,
 * each with nested product data, options, prices, etc.
 *
 * SWIFT IMPLEMENTATION:
 * ```swift
 * struct OrderProductsData: Codable {
 *     let items: [OrderProductItem]
 * }
 *
 * struct OrderProductItem: Codable {
 *     let vat: VatData?
 *     let gram: Int
 *     let shop: ShopRefData
 *     let amount: Int
 *     let comment: String
 *     let options: [OrderProductOption]
 *     let persons: Int
 *     let product: ProductData
 *     let category: CategoryRefData
 *     let amountFree: Int
 *     let productPrice: ProductPriceData?
 *     let discountPrices: CalculatedPrices?
 *     let calculatedPrices: CalculatedPrices
 * }
 * ```
 */
class OrderProductsData
{
    /** @var OrderProductItem[] */
    public array $items = [];

    public function __construct(array $data = [])
    {
        $this->items = array_map(
            fn($item) => new OrderProductItem($item),
            $data
        );
    }
}

class OrderProductItem
{
    public ?VatData $vat = null;
    public int $gram = 0;
    public ?ShopRefData $shop = null;
    public int $amount = 1;
    public string $comment = '';
    /** @var OrderProductOption[] */
    public array $options = [];
    public int $persons = 1;
    public ?ProductData $product = null;
    public ?CategoryRefData $category = null;
    public int $amount_free = 0;
    public ?ProductPriceData $product_price = null;
    public ?CalculatedPrices $discount_prices = null;
    public ?CalculatedPrices $calculated_prices = null;

    public function __construct(array $data = [])
    {
        if (isset($data['vat'])) {
            $this->vat = new VatData($data['vat']);
        }
        $this->gram = $data['gram'] ?? 0;
        if (isset($data['shop'])) {
            $this->shop = new ShopRefData($data['shop']);
        }
        $this->amount = $data['amount'] ?? 1;
        $this->comment = $data['comment'] ?? '';
        $this->options = array_map(
            fn($opt) => new OrderProductOption($opt),
            $data['options'] ?? []
        );
        $this->persons = $data['persons'] ?? 1;
        if (isset($data['product'])) {
            $this->product = new ProductData($data['product']);
        }
        if (isset($data['category'])) {
            $this->category = new CategoryRefData($data['category']);
        }
        $this->amount_free = $data['amount_free'] ?? 0;
        if (isset($data['product_price'])) {
            $this->product_price = new ProductPriceData($data['product_price']);
        }
        if (isset($data['discount_prices'])) {
            $this->discount_prices = new CalculatedPrices($data['discount_prices']);
        }
        if (isset($data['calculated_prices'])) {
            $this->calculated_prices = new CalculatedPrices($data['calculated_prices']);
        }
    }
}

class VatData
{
    public int $rate = 21;
    public ?int $id = null;

    public function __construct(array $data = [])
    {
        $this->rate = $data['rate'] ?? 21;
        $this->id = $data['id'] ?? null;
    }
}

class ShopRefData
{
    public int $id = 0;

    public function __construct(array $data = [])
    {
        $this->id = $data['id'] ?? 0;
    }
}

class ProductData
{
    public int $id = 0;
    public string $plu = '';
    public float $ppp = 0;
    public ?VatData $vat = null;
    public string $code = '';
    public string $name = '';
    public float $price = 0;
    public ?MinMaxData $min_max = null;
    public bool $use_ppp = false;
    public ?CategoryRefData $category = null;
    public ?ProductWarrantyData $warranty = null;
    public int $price_type = 0;
    public float $targetPrice = 0;
    public int $only_on_isop = 0;
    public bool $weight_based = false;
    public string $name_translated = '';
    public int $temperatureType = 0;

    public function __construct(array $data = [])
    {
        $this->id = $data['id'] ?? 0;
        $this->plu = $data['plu'] ?? '';
        $this->ppp = (float) ($data['ppp'] ?? 0);
        if (isset($data['vat']) && is_array($data['vat'])) {
            $this->vat = new VatData($data['vat']);
        }
        $this->code = $data['code'] ?? '';
        $this->name = $data['name'] ?? '';
        $this->price = (float) ($data['price'] ?? 0);
        if (isset($data['min_max'])) {
            $this->min_max = new MinMaxData($data['min_max']);
        }
        $this->use_ppp = $data['use_ppp'] ?? false;
        if (isset($data['category'])) {
            $this->category = new CategoryRefData($data['category']);
        }
        if (isset($data['warranty'])) {
            $this->warranty = new ProductWarrantyData($data['warranty']);
        }
        $this->price_type = $data['price_type'] ?? 0;
        $this->targetPrice = (float) ($data['targetPrice'] ?? 0);
        $this->only_on_isop = $data['only_on_isop'] ?? 0;
        $this->weight_based = $data['weight_based'] ?? false;
        $this->name_translated = $data['name_translated'] ?? '';
        $this->temperatureType = $data['temperatureType'] ?? 0;
    }
}

class MinMaxData
{
    public ?StockMinMaxData $stock = null;
    public ?AmountMinMaxData $amount = null;
    public ?WeightMinMaxData $weight = null;
    public ?PersonsMinMaxData $persons = null;

    public function __construct(array $data = [])
    {
        if (isset($data['stock'])) {
            $this->stock = new StockMinMaxData($data['stock']);
        }
        if (isset($data['amount'])) {
            $this->amount = new AmountMinMaxData($data['amount']);
        }
        if (isset($data['weight'])) {
            $this->weight = new WeightMinMaxData($data['weight']);
        }
        if (isset($data['persons'])) {
            $this->persons = new PersonsMinMaxData($data['persons']);
        }
    }
}

class StockMinMaxData
{
    public ?int $amount = null;

    public function __construct(array $data = [])
    {
        $this->amount = $data['amount'] ?? null;
    }
}

class AmountMinMaxData
{
    public ?int $max = null;
    public int $min = 1;
    public int $suggested = 1;

    public function __construct(array $data = [])
    {
        $this->max = $data['max'] ?? null;
        $this->min = $data['min'] ?? 1;
        $this->suggested = $data['suggested'] ?? 1;
    }
}

class WeightMinMaxData
{
    public ?int $max = null;
    public int $min = 0;
    public int $suggested = 100;

    public function __construct(array $data = [])
    {
        $this->max = $data['max'] ?? null;
        $this->min = $data['min'] ?? 0;
        $this->suggested = $data['suggested'] ?? 100;
    }
}

class PersonsMinMaxData
{
    public ?int $max = null;
    public int $min = 0;
    public int $suggested = 1;

    public function __construct(array $data = [])
    {
        $this->max = $data['max'] ?? null;
        $this->min = $data['min'] ?? 0;
        $this->suggested = $data['suggested'] ?? 1;
    }
}

class ProductWarrantyData
{
    public int $type = 0;
    public float $price = 0;

    public function __construct(array $data = [])
    {
        $this->type = $data['type'] ?? 0;
        $this->price = (float) ($data['price'] ?? 0);
    }
}

class CategoryRefData
{
    public int $id = 0;
    public string $name = '';
    public string $name_translated = '';

    public function __construct(array $data = [])
    {
        $this->id = $data['id'] ?? 0;
        $this->name = $data['name'] ?? '';
        $this->name_translated = $data['name_translated'] ?? '';
    }
}

class ProductPriceData
{
    public ?int $id = null;
    public string $name = '';
    public float $price = 0;
    public ?ProductWarrantyData $warranty = null;
    public array $translations = [];

    public function __construct(array $data = [])
    {
        $this->id = $data['id'] ?? null;
        $this->name = $data['name'] ?? '';
        $this->price = (float) ($data['price'] ?? 0);
        if (isset($data['warranty'])) {
            $this->warranty = new ProductWarrantyData($data['warranty']);
        }
        $this->translations = $data['translations'] ?? [];
    }
}

class CalculatedPrices
{
    public float $price = 0;
    public float $unit_price = 0;

    public function __construct(array $data = [])
    {
        $this->price = (float) ($data['price'] ?? 0);
        $this->unit_price = (float) ($data['unit_price'] ?? 0);
    }
}

class OrderProductOption
{
    public int $amount = 1;
    public ?ProductData $product = null;
    public ?ProductPriceData $product_price = null;

    public function __construct(array $data = [])
    {
        $this->amount = $data['amount'] ?? 1;
        if (isset($data['product'])) {
            $this->product = new ProductData($data['product']);
        }
        if (isset($data['product_price'])) {
            $this->product_price = new ProductPriceData($data['product_price']);
        }
    }
}
