//
//  Product.swift
//  bap-swift
//
//  Created by Jan Lecoutere on 22/03/2026.
//

import NewCodable

@JSONDecodable
struct ProductSettings {
    let seo: ProductSettingsSeo?
    let photo: ProductSettingsPhoto?
    let price: ProductSettingsPrice?
    let stock: ProductSettingsStock?
    // NOTE: The php side does not parse this into a type, just a unstructured array
    let photos: [ProductSettingsPhoto]?
    @CodingKey("photos_fs")
    let photosFs: ProductSettingsPhotosFs?
    let maxOrderAmount: Int?
    let minOrderAmount: Int?
    let suggestedOrderWeight: Int?
    let nutrients: ProductSettingsNutrients?
    @CodingKey("_version")
    let version: String?
}

@JSONDecodable
struct ProductSettingsSeo {
    // Can be Empty array, null or Dictionary[string:string]
    let url: FlexibleValue?
    let title: FlexibleValue?
    let description: FlexibleValue?
}

@JSONDecodable
struct ProductSettingsPhoto {
    let type: String?
    @CodingKey("file_id")
    let fileId: Int?
    let resolutions: [ProductSettingsPhotoResolution]
    @CodingKey("white_background")
    let whiteBackground: Bool
}

@JSONDecodable
struct ProductSettingsPhotoResolution {
    let url: String?
    let width: Int?
    let height: Int?
}

@JSONDecodable
struct ProductSettingsPrice {
    // NOTE: the array is always empty in the sample data
    let deviations: [String]
}

@JSONDecodable
struct ProductSettingsStock {
    let amount: Double?
    let soldout: Bool?
    @CodingKey("soldout_until")
    let soldoutUntil: String?
    @CodingKey("max_amount_per_day")
    let maxAmountPerDay: Int?
    @CodingKey("max_weight_per_day")
    let maxWeightPerDay: Double?
    @CodingKey("max_amount_per_week")
    let maxAmountPerWeek: Int?
    @CodingKey("max_weight_per_week")
    let maxWeightPerWeek: Double?
}

@JSONDecodable
struct ProductSettingsPhotosFs {
    let items: [ProductSettingsPhoto]
}

@JSONDecodable
struct ProductSettingsNutrients {
    let items: [ProductSettingsNutrient]
}

@JSONDecodable
struct ProductSettingsNutrient {
    let type: String
    let value: Double
    let unitLabel: String

    enum CodingKeys: String, CodingKey {
        case type
        case value
        case unitLabel = "unit_label"
    }
}
