import Foundation
import SwiftUI
import UIKit

// MARK: - HSL

struct HSL {
    var h: Double  // 0..<360
    var s: Double  // 0...1
    var l: Double  // 0...1
}

// MARK: - RGB

struct RGBColor: Hashable {
    var r: Double
    var g: Double
    var b: Double

    init(r: Double, g: Double, b: Double) {
        self.r = min(max(r, 0), 1)
        self.g = min(max(g, 0), 1)
        self.b = min(max(b, 0), 1)
    }

    init?(hex: String) {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if value.hasPrefix("#") { value.removeFirst() }
        if value.count == 3 {
            value = value.map { "\($0)\($0)" }.joined()
        }
        guard value.count == 6, let number = UInt32(value, radix: 16) else { return nil }
        self.init(r: Double((number >> 16) & 0xFF) / 255.0,
                  g: Double((number >> 8) & 0xFF) / 255.0,
                  b: Double(number & 0xFF) / 255.0)
    }

    var hex: String {
        let red = Int((r * 255).rounded())
        let green = Int((g * 255).rounded())
        let blue = Int((b * 255).rounded())
        return String(format: "#%02X%02X%02X", red, green, blue)
    }

    var hsl: HSL {
        let maxValue = max(r, g, b)
        let minValue = min(r, g, b)
        let lightness = (maxValue + minValue) / 2
        let delta = maxValue - minValue
        var hue: Double = 0
        var saturation: Double = 0

        if delta > 0.0001 {
            saturation = lightness > 0.5
                ? delta / (2 - maxValue - minValue)
                : delta / (maxValue + minValue)
            if maxValue == r {
                hue = (g - b) / delta + (g < b ? 6 : 0)
            } else if maxValue == g {
                hue = (b - r) / delta + 2
            } else {
                hue = (r - g) / delta + 4
            }
            hue *= 60
        }
        if hue < 0 { hue += 360 }

        return HSL(h: hue, s: saturation, l: lightness)
    }

    /// Luminanza percepita: utile per decidere testo chiaro o scuro.
    var luminance: Double {
        0.299 * r + 0.587 * g + 0.114 * b
    }

    var color: Color {
        Color(red: r, green: g, blue: b)
    }

    var uiColor: UIColor {
        UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1)
    }

    func blended(with other: RGBColor, amount: Double) -> RGBColor {
        let t = min(max(amount, 0), 1)
        return RGBColor(r: r + (other.r - r) * t,
                        g: g + (other.g - g) * t,
                        b: b + (other.b - b) * t)
    }

    /// Nome descrittivo in italiano, es. "azzurro chiaro", "blu navy", "cammello".
    var descriptiveName: String {
        let family = ColorFamily.family(for: self)
        let hsl = self.hsl

        switch family {
        case .black: return "nero"
        case .white: return "bianco"
        case .gray, .beige:
            if family == .beige, hsl.s >= 0.25, hsl.h >= 22, hsl.h <= 45 { return "cammello" }
            return family.label.lowercased()
        default:
            var base = family.label.lowercased()
            if family == .blue { base = hsl.l > 0.55 ? "azzurro" : "blu" }
            if family == .navy { base = "blu navy" }
            if hsl.l >= 0.78 && family != .yellow { return base + " chiaro" }
            if hsl.l <= 0.28 { return base + " scuro" }
            return base
        }
    }
}

// MARK: - Famiglie di colore

enum ColorFamily: String, CaseIterable, Identifiable, Codable {
    case black
    case white
    case gray
    case beige
    case brown
    case red
    case orange
    case yellow
    case green
    case teal
    case blue
    case navy
    case purple
    case pink

    var id: String { rawValue }

    var label: String {
        switch self {
        case .black: return "Nero"
        case .white: return "Bianco"
        case .gray: return "Grigio"
        case .beige: return "Beige"
        case .brown: return "Marrone"
        case .red: return "Rosso"
        case .orange: return "Arancio"
        case .yellow: return "Giallo"
        case .green: return "Verde"
        case .teal: return "Verde acqua"
        case .blue: return "Azzurro"
        case .navy: return "Blu navy"
        case .purple: return "Viola"
        case .pink: return "Rosa"
        }
    }

    /// I neutri si abbinano con tutto: sono la base del guardaroba.
    var isNeutral: Bool {
        switch self {
        case .black, .white, .gray, .beige, .brown: return true
        default: return false
        }
    }

    var referenceHex: String {
        switch self {
        case .black: return "#1B1B1B"
        case .white: return "#F7F5EF"
        case .gray: return "#8C8C8C"
        case .beige: return "#D9C7A7"
        case .brown: return "#6B4B32"
        case .red: return "#B23A34"
        case .orange: return "#C4762C"
        case .yellow: return "#D9B23C"
        case .green: return "#4C6B45"
        case .teal: return "#2E6E6A"
        case .blue: return "#6E96BC"
        case .navy: return "#26364F"
        case .purple: return "#5B4A75"
        case .pink: return "#D98A9A"
        }
    }

    var referenceRGB: RGBColor {
        RGBColor(hex: referenceHex) ?? RGBColor(r: 0.7, g: 0.7, b: 0.7)
    }

    /// Aggettivo accordato al nome del capo ("maglia bianca", "pantalone nero", "scarpe bianche").
    func adjective(for gender: Gender) -> String {
        let forms: (masculine: String, feminine: String, plural: String)
        switch self {
        case .black: forms = ("nero", "nera", "nere")
        case .white: forms = ("bianco", "bianca", "bianche")
        case .gray: forms = ("grigio", "grigia", "grigie")
        case .beige: forms = ("beige", "beige", "beige")
        case .brown: forms = ("marrone", "marrone", "marroni")
        case .red: forms = ("rosso", "rossa", "rosse")
        case .orange: forms = ("arancione", "arancione", "arancioni")
        case .yellow: forms = ("giallo", "gialla", "gialle")
        case .green: forms = ("verde", "verde", "verdi")
        case .teal: forms = ("verde acqua", "verde acqua", "verde acqua")
        case .blue: forms = ("azzurro", "azzurra", "azzurre")
        case .navy: forms = ("blu navy", "blu navy", "blu navy")
        case .purple: forms = ("viola", "viola", "viola")
        case .pink: forms = ("rosa", "rosa", "rosa")
        }

        switch gender {
        case .masculine: return forms.masculine
        case .feminine: return forms.feminine
        case .femininePlural: return forms.plural
        }
    }

    /// Classificazione del colore in una famiglia, dal più generico al più preciso.
    static func family(for color: RGBColor) -> ColorFamily {
        let hsl = color.hsl
        let h = hsl.h
        let s = hsl.s
        let l = hsl.l

        if l <= 0.10 { return .black }
        if l >= 0.955 && s < 0.12 { return .white }

        if s < 0.105 {
            if l >= 0.86 { return .white }
            if l <= 0.20 { return .black }
            return .gray
        }

        // Rossi e rosa
        if h < 16 || h >= 342 {
            if l >= 0.74 && s < 0.55 { return .pink }
            return .red
        }

        // Arancio, marrone, beige, cammello (18° - 50°)
        if h < 50 {
            if l >= 0.80 && s < 0.42 { return .beige }
            if s < 0.20 { return l > 0.62 ? .beige : .gray }
            if l <= 0.40 { return .brown }
            if s < 0.42 && l <= 0.70 { return .brown }
            return .orange
        }

        // Giallo e cammello (50° - 72°)
        if h < 72 {
            if l >= 0.78 && s < 0.42 { return .beige }
            if l <= 0.42 { return .brown }
            if s < 0.36 && l <= 0.72 { return .beige }
            return .yellow
        }

        // Verdi (72° - 160°)
        if h < 160 { return .green }

        // Verde acqua (160° - 195°)
        if h < 195 { return .teal }

        // Blu e navy (195° - 260°)
        if h < 260 {
            if l < 0.34 && s > 0.18 { return .navy }
            return .blue
        }

        // Viola (260° - 290°)
        if h < 290 { return .purple }

        // Rosa (290° - 342°)
        if l >= 0.72 && s < 0.55 { return .pink }
        return .purple
    }
}

// MARK: - Ponti SwiftUI

extension Color {
    init(hex: String) {
        let rgb = RGBColor(hex: hex) ?? RGBColor(r: 0.7, g: 0.68, b: 0.65)
        self.init(red: rgb.r, green: rgb.g, blue: rgb.b)
    }

    var hexString: String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return "#BDB6AA"
        }
        let r = Int((min(max(red, 0), 1) * 255).rounded())
        let g = Int((min(max(green, 0), 1) * 255).rounded())
        let b = Int((min(max(blue, 0), 1) * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

extension String {
    var capitalizedFirst: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}
