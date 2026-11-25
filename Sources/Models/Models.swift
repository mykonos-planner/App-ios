import Foundation

// MARK: - Grammatical gender (usato per i consigli in italiano)

enum Gender {
    case masculine
    case feminine
    case femininePlural
}

// MARK: - Categoria

enum GarmentCategory: String, Codable, CaseIterable, Identifiable {
    case top
    case bottom
    case dress
    case outerwear
    case shoes
    case accessory

    var id: String { rawValue }

    var title: String {
        switch self {
        case .top: return "Parte superiore"
        case .bottom: return "Parte inferiore"
        case .dress: return "Vestito"
        case .outerwear: return "Capospalla"
        case .shoes: return "Scarpe"
        case .accessory: return "Accessorio"
        }
    }

    var shortTitle: String {
        switch self {
        case .top: return "Top"
        case .bottom: return "Bottom"
        case .dress: return "Vestito"
        case .outerwear: return "Capospalla"
        case .shoes: return "Scarpe"
        case .accessory: return "Accessorio"
        }
    }

    var iconName: String {
        switch self {
        case .top: return "tshirt"
        case .bottom: return "rectangle.portrait"
        case .dress: return "figure.stand"
        case .outerwear: return "wind"
        case .shoes: return "figure.walk"
        case .accessory: return "sparkle"
        }
    }

    /// Nome generico usato nei consigli: "una maglia bianca", "un pantalone nero".
    var noun: String {
        switch self {
        case .top: return "maglia"
        case .bottom: return "pantalone"
        case .dress: return "vestito"
        case .outerwear: return "giacca"
        case .shoes: return "scarpe"
        case .accessory: return "accessorio"
        }
    }

    var gender: Gender {
        switch self {
        case .top, .dress, .outerwear: return .feminine
        case .shoes: return .femininePlural
        case .bottom, .accessory: return .masculine
        }
    }

    var slotOrder: Int {
        switch self {
        case .dress: return 0
        case .top: return 1
        case .bottom: return 2
        case .outerwear: return 3
        case .shoes: return 4
        case .accessory: return 5
        }
    }
}

// MARK: - Stagioni

enum Season: String, Codable, CaseIterable, Identifiable {
    case spring
    case summer
    case autumn
    case winter

    var id: String { rawValue }

    var title: String {
        switch self {
        case .spring: return "Primavera"
        case .summer: return "Estate"
        case .autumn: return "Autunno"
        case .winter: return "Inverno"
        }
    }

    var iconName: String {
        switch self {
        case .spring: return "leaf"
        case .summer: return "sun.max"
        case .autumn: return "cloud.sun"
        case .winter: return "snowflake"
        }
    }
}

// MARK: - Occasione

enum Formality: String, Codable, CaseIterable, Identifiable {
    case sporty
    case casual
    case smartCasual
    case formal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sporty: return "Sportivo"
        case .casual: return "Casual"
        case .smartCasual: return "Smart casual"
        case .formal: return "Elegante"
        }
    }

    var rank: Int {
        switch self {
        case .sporty: return 0
        case .casual: return 1
        case .smartCasual: return 2
        case .formal: return 3
        }
    }
}

// MARK: - Fantasia

enum Pattern: String, Codable, CaseIterable, Identifiable {
    case solid
    case striped
    case checked
    case floral
    case graphic
    case textured

    var id: String { rawValue }

    var title: String {
        switch self {
        case .solid: return "Tinta unita"
        case .striped: return "Righe"
        case .checked: return "Quadri"
        case .floral: return "Fiori"
        case .graphic: return "Stampa"
        case .textured: return "Trama"
        }
    }
}

// MARK: - Capo

struct Garment: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var category: GarmentCategory
    var colorHex: String
    var secondColorHex: String?
    var pattern: Pattern = .solid
    var formality: Formality = .casual
    var seasons: Set<Season> = Set(Season.allCases)
    var warmth: Int = 3
    var brand: String = ""
    var notes: String = ""
    var imageName: String?
    var isFavorite: Bool = false
    var createdAt: Date = Date()

    var rgb: RGBColor {
        RGBColor(hex: colorHex) ?? RGBColor(r: 0.7, g: 0.68, b: 0.65)
    }

    var secondRGB: RGBColor? {
        guard let hex = secondColorHex else { return nil }
        return RGBColor(hex: hex)
    }

    /// I colori che contano per l'abbinamento (tinta unita = uno solo).
    var palette: [RGBColor] {
        if let second = secondRGB { return [rgb, second] }
        return [rgb]
    }

    var seasonText: String {
        let ordered = Season.allCases.filter { seasons.contains($0) }
        if ordered.isEmpty { return "—" }
        if ordered.count == Season.allCases.count { return "Tutte le stagioni" }
        return ordered.map { $0.title }.joined(separator: ", ")
    }

    var warmthText: String {
        "\(min(max(warmth, 1), 5))/5"
    }
}

extension Garment {
    enum CodingKeys: String, CodingKey {
        case id, name, category, colorHex, secondColorHex, pattern, formality
        case seasons, warmth, brand, notes, imageName, isFavorite, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Capo"
        category = try container.decodeIfPresent(GarmentCategory.self, forKey: .category) ?? .top
        colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex) ?? "#BDB6AA"
        secondColorHex = try container.decodeIfPresent(String.self, forKey: .secondColorHex)
        pattern = try container.decodeIfPresent(Pattern.self, forKey: .pattern) ?? .solid
        formality = try container.decodeIfPresent(Formality.self, forKey: .formality) ?? .casual
        let storedSeasons = try container.decodeIfPresent([Season].self, forKey: .seasons) ?? Season.allCases
        seasons = Set(storedSeasons)
        warmth = try container.decodeIfPresent(Int.self, forKey: .warmth) ?? 3
        brand = try container.decodeIfPresent(String.self, forKey: .brand) ?? ""
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        imageName = try container.decodeIfPresent(String.self, forKey: .imageName)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}

// MARK: - Outfit

struct Outfit: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var itemIDs: [UUID]
    var note: String = ""
    var createdAt: Date = Date()
    var savedScore: Int = 0
    var isFavorite: Bool = false
}

extension Outfit {
    enum CodingKeys: String, CodingKey {
        case id, name, itemIDs, note, createdAt, savedScore, isFavorite
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Outfit"
        itemIDs = try container.decodeIfPresent([UUID].self, forKey: .itemIDs) ?? []
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        savedScore = try container.decodeIfPresent(Int.self, forKey: .savedScore) ?? 0
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
    }
}

// MARK: - Bozza per l'editor

struct GarmentDraft: Identifiable {
    let id = UUID()
    var garment: Garment
}
