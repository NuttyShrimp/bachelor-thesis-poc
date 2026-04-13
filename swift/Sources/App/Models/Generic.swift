enum FlexibleValue: Codable {
    case null
    case string(String)
    case dictionary([String: String])
    case array([String])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let dict = try? container.decode([String: String].self) {
            self = .dictionary(dict)
        } else if let array = try? container.decode([String].self) {
            self = .array(array)
        } else if let str = try? container.decode(String.self) {
            self = .string(str)
        } else {
            throw DecodingError.typeMismatch(
                FlexibleValue.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected null, [String: String], or [String], "
                )
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .dictionary(let dict):
            try container.encode(dict)
        case .array(let array):
            try container.encode(array)
        case .string(let str):
            try container.encode(str)
        }
    }
}
