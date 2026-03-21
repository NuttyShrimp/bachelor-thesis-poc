<?php

namespace App\Benchmarks\Dtos;

/**
 * PRODUCT SETTINGS DTO
 *
 * Maps the settings_json column from products.
 * This mirrors the SettingsData DTO in BakerOnline.
 *
 * SWIFT IMPLEMENTATION:
 * ```swift
 * struct ProductSettings: Codable {
 *     let seo: SeoData?
 *     let photo: String?
 *     let price: PriceSettings?
 *     let stock: StockSettings?
 *     let photos: [String]?
 *     let photosFsItems: [ImageData]?
 *     let maxOrderAmount: Int?
 *     let minOrderAmount: Int?
 *     let suggestedOrderWeight: Int?
 *     let nutrients: NutrientsData?
 *
 *     enum CodingKeys: String, CodingKey {
 *         case seo, photo, price, stock, photos
 *         case photosFsItems = "photos_fs"
 *         case maxOrderAmount, minOrderAmount, suggestedOrderWeight
 *         case nutrients
 *     }
 * }
 * ```
 */
class ProductSettingsData
{
    public ?SeoData $seo = null;
    public mixed $photo = null; // Can be string, array, or null
    public ?PriceSettingsData $price = null;
    public ?StockSettingsData $stock = null;
    public array $photos = [];
    public ?PhotosFsData $photos_fs = null;
    public ?int $maxOrderAmount = null;
    public int $minOrderAmount = 1;
    public int $suggestedOrderWeight = 0;
    public ?NutrientsData $nutrients = null;
    public ?string $_version = null;

    public function __construct(array $data = [])
    {
        if (isset($data['seo']) && is_array($data['seo'])) {
            $this->seo = new SeoData($data['seo']);
        }
        $this->photo = $data['photo'] ?? null;

        if (isset($data['price'])) {
            $this->price = new PriceSettingsData($data['price']);
        }
        if (isset($data['stock'])) {
            $this->stock = new StockSettingsData($data['stock']);
        }
        $this->photos = $data['photos'] ?? [];

        if (isset($data['photos_fs'])) {
            $this->photos_fs = new PhotosFsData($data['photos_fs']);
        }

        $this->maxOrderAmount = $data['maxOrderAmount'] ?? null;
        $this->minOrderAmount = $data['minOrderAmount'] ?? 1;
        $this->suggestedOrderWeight = $data['suggestedOrderWeight'] ?? 0;

        if (isset($data['nutrients'])) {
            $this->nutrients = new NutrientsData($data['nutrients']);
        }

        $this->_version = $data['_version'] ?? null;
    }
}

class SeoData
{
    public array $url = [];
    public array $title = [];
    public array $description = [];

    public function __construct(array $data = [])
    {
        // Handle mixed types from real data - can be string or array
        $this->url = is_array($data['url'] ?? []) ? ($data['url'] ?? []) : [];
        $this->title = is_array($data['title'] ?? []) ? ($data['title'] ?? []) : [];
        $this->description = is_array($data['description'] ?? []) ? ($data['description'] ?? []) : [];
    }
}

class PriceSettingsData
{
    public array $deviations = [];

    public function __construct(array $data = [])
    {
        $this->deviations = array_map(
            fn($d) => new PriceDeviationData($d),
            $data['deviations'] ?? []
        );
    }
}

class PriceDeviationData
{
    public int $dow = 0;
    public float $price = 0;

    public function __construct(array $data = [])
    {
        $this->dow = $data['dow'] ?? 0;
        $this->price = (float) ($data['price'] ?? 0);
    }
}

class StockSettingsData
{
    public ?int $amount = null;
    public bool $soldout = false;
    public ?string $soldoutUntil = null;
    public ?int $maxAmountPerDay = null;
    public ?int $maxWeightPerDay = null;
    public ?int $maxAmountPerWeek = null;
    public ?int $maxWeightPerWeek = null;

    public function __construct(array $data = [])
    {
        $this->amount = isset($data['amount']) ? (int) $data['amount'] : null;
        $this->soldout = (bool) ($data['soldout'] ?? false);
        $this->soldoutUntil = $data['soldoutUntil'] ?? null;
        $this->maxAmountPerDay = isset($data['maxAmountPerDay']) ? (int) $data['maxAmountPerDay'] : null;
        $this->maxWeightPerDay = isset($data['maxWeightPerDay']) ? (int) $data['maxWeightPerDay'] : null;
        $this->maxAmountPerWeek = isset($data['maxAmountPerWeek']) ? (int) $data['maxAmountPerWeek'] : null;
        $this->maxWeightPerWeek = isset($data['maxWeightPerWeek']) ? (int) $data['maxWeightPerWeek'] : null;
    }
}

class PhotosFsData
{
    public array $items = [];

    public function __construct(array $data = [])
    {
        $this->items = array_map(
            fn($item) => new ImageData($item),
            $data['items'] ?? []
        );
    }
}

class ImageData
{
    public ?int $id = null;
    public ?string $name = null;
    public ?string $path = null;
    public array $resolutions = [];

    public function __construct(array $data = [])
    {
        $this->id = $data['id'] ?? null;
        $this->name = $data['name'] ?? null;
        $this->path = $data['path'] ?? null;
        $this->resolutions = array_map(
            fn($r) => new ResolutionData($r),
            $data['resolutions'] ?? []
        );
    }
}

class ResolutionData
{
    public ?FileData $file = null;
    public ?SizeData $size = null;
    public ?DimensionData $resolution = null;

    public function __construct(array $data = [])
    {
        if (isset($data['file'])) {
            $this->file = new FileData($data['file']);
        }
        if (isset($data['size'])) {
            $this->size = new SizeData($data['size']);
        }
        if (isset($data['resolution'])) {
            $this->resolution = new DimensionData($data['resolution']);
        }
    }
}

class FileData
{
    public ?string $path = null;
    public int $size = 0;

    public function __construct(array $data = [])
    {
        $this->path = $data['path'] ?? null;
        $this->size = $data['size'] ?? 0;
    }
}

class SizeData
{
    public int $width = 0;
    public int $height = 0;

    public function __construct(array $data = [])
    {
        $this->width = $data['width'] ?? 0;
        $this->height = $data['height'] ?? 0;
    }
}

class DimensionData
{
    public int $width = 0;
    public int $height = 0;

    public function __construct(array $data = [])
    {
        $this->width = $data['width'] ?? 0;
        $this->height = $data['height'] ?? 0;
    }
}

class NutrientsData
{
    public array $items = [];

    public function __construct(array $data = [])
    {
        $this->items = array_map(
            fn($item) => new NutrientItem($item),
            $data['items'] ?? []
        );
    }
}

class NutrientItem
{
    public string $type = '';
    public float $value = 0;
    public string $unit_label = '';

    public function __construct(array $data = [])
    {
        $this->type = $data['type'] ?? '';
        $this->value = (float) ($data['value'] ?? 0);
        $this->unit_label = $data['unit_label'] ?? '';
    }
}
