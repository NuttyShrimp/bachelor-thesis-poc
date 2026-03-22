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
    let photos: [ProductSettingsPhoto]
    let photosFs: ProductSettingsPhotosFs?
    let maxOrder: Int?
    let minOrder: Int
    let suggestedOrderWeight: Int
    let nutrients: ProductSettingsNutrients?
    let version: String?
}

struct ProductSettingsSeo: Decodable {
    let url: [String: String]
    let title: [String: String]
    let description: [String: String]
}

struct ProductSettingsPhoto: Decodable {
    let type: String
    let fileId: Int
    let resolutions: [ProductSettingsPhotoResolution]
    let whiteBackground: Bool
}

struct ProductSettingsPhotoResolution: Decodable {
    let url: String
    let width: Int
    let height: Int
}

struct ProductSettingsPrice: Decodable {
    // NOTE: the array is always empty in the sample data
    let deviations: [String];
}

struct ProductSettingsStock: Decodable {
    let amount: Int?
    let soldout: Bool
    let soldoutUntil: String?
    let maxAmountPerDay: Int?
    let maxWeightPerDay: Int?
    let maxAmountPerWeek: Int?
    let maxWeightPerWeek: Int?
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
