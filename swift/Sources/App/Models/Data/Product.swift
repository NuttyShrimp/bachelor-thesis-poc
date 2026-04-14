//
//  Product.swift
//  bap-swift
//
//  Created by Jan Lecoutere on 22/03/2026.
//

struct ProductSettings: Decodable {
    let seo: ProductSettingsSeo?
    let photo: ProductSettingsPhoto?
    let price: ProductSettingsPrice?
    let stock: ProductSettingsStock?
    // NOTE: The php side does not parse this into a type, just a unstructured array
    let photos: [ProductSettingsPhoto]?
    let photosFs: ProductSettingsPhotosFs?
    let maxOrderAmount: Int?
    let minOrderAmount: Int?
    let suggestedOrderWeight: Int?
    let nutrients: ProductSettingsNutrients?
    let version: String?

    enum CodingKeys: String, CodingKey {
        case seo
        case photo
        case price
        case stock
        case photos
        case photosFs = "photos_fs"
        case maxOrderAmount
        case minOrderAmount
        case suggestedOrderWeight
        case nutrients
        case version = "_version"
    }
}

struct ProductSettingsSeo: Decodable {
    // Can be Empty array, null or Dictionary[string:string]
    let url: FlexibleValue?
    let title: FlexibleValue?
    let description: FlexibleValue?
}

struct ProductSettingsPhoto: Decodable {
    let type: String?
    let fileId: Int?
    let resolutions: [ProductSettingsPhotoResolution]
    let whiteBackground: Bool
}

struct ProductSettingsPhotoResolution: Decodable {
    let url: String?
    let width: Int?
    let height: Int?
}

struct ProductSettingsPrice: Decodable {
    // NOTE: the array is always empty in the sample data
    let deviations: [String]
}

struct ProductSettingsStock: Decodable {
    let amount: Double?
    let soldout: Bool?
    let soldoutUntil: String?
    let maxAmountPerDay: Int?
    let maxWeightPerDay: Double?
    let maxAmountPerWeek: Int?
    let maxWeightPerWeek: Double?
}

struct ProductSettingsPhotosFs: Decodable {
    let items: [ProductSettingsPhoto]
}

struct ProductSettingsNutrients: Decodable {
    let items: [ProductSettingsNutrient]
}

struct ProductSettingsNutrient: Decodable {
    let type: String
    let value: Double
    let unitLabel: String
}
