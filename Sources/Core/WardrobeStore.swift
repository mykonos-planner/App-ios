import Foundation
import Combine
import UIKit

/// Persistenza locale: un file JSON + cartella immagini. Nessuna rete, nessun cloud.
final class WardrobeStore: ObservableObject {

    @Published private(set) var garments: [Garment] = []
    @Published private(set) var outfits: [Outfit] = []

    private let rootDirectory: URL
    private let imagesDirectory: URL
    private let dataURL: URL
    private let imageCache = NSCache<NSString, UIImage>()

    private struct Payload: Codable {
        var garments: [Garment] = []
        var outfits: [Outfit] = []
    }

    init() {
        let base: URL
        if let support = try? FileManager.default.url(for: .applicationSupportDirectory,
                                                     in: .userDomainMask,
                                                     appropriateFor: nil,
                                                     create: true) {
            base = support
        } else {
            base = FileManager.default.temporaryDirectory
        }
        rootDirectory = base.appendingPathComponent("Atelier", isDirectory: true)
        imagesDirectory = rootDirectory.appendingPathComponent("Images", isDirectory: true)
        dataURL = rootDirectory.appendingPathComponent("wardrobe.json")
        imageCache.countLimit = 160
        try? FileManager.default.createDirectory(at: imagesDirectory,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)
        load()
    }

    // MARK: - Accesso

    func garment(with id: UUID) -> Garment? {
        garments.first { $0.id == id }
    }

    func items(for outfit: Outfit) -> [Garment] {
        outfit.itemIDs.compactMap { garment(with: $0) }
    }

    func image(for garment: Garment) -> UIImage? {
        guard let name = garment.imageName else { return nil }
        if let cached = imageCache.object(forKey: name as NSString) { return cached }
        let url = imagesDirectory.appendingPathComponent(name)
        guard let image = UIImage(contentsOfFile: url.path) else { return nil }
        imageCache.setObject(image, forKey: name as NSString)
        return image
    }

    // MARK: - Modifiche

    func upsert(_ garment: Garment, image: UIImage?, removeImage: Bool) {
        var updated = garment
        if let image, let storedName = storeImage(image) {
            if let oldName = updated.imageName { deleteImage(named: oldName) }
            updated.imageName = storedName
        } else if removeImage, let oldName = updated.imageName {
            deleteImage(named: oldName)
            updated.imageName = nil
        }

        if let index = garments.firstIndex(where: { $0.id == updated.id }) {
            garments[index] = updated
        } else {
            garments.insert(updated, at: 0)
        }
        persist()
    }

    func delete(_ garment: Garment) {
        if let name = garment.imageName { deleteImage(named: name) }
        garments.removeAll { $0.id == garment.id }
        outfits = outfits
            .map { outfit in
                var copy = outfit
                copy.itemIDs.removeAll { $0 == garment.id }
                return copy
            }
            .filter { !$0.itemIDs.isEmpty }
        persist()
    }

    func saveOutfit(_ outfit: Outfit) {
        if let index = outfits.firstIndex(where: { $0.id == outfit.id }) {
            outfits[index] = outfit
        } else {
            outfits.insert(outfit, at: 0)
        }
        persist()
    }

    func deleteOutfit(_ outfit: Outfit) {
        outfits.removeAll { $0.id == outfit.id }
        persist()
    }

    // MARK: - Immagini

    @discardableResult
    private func storeImage(_ image: UIImage) -> String? {
        let resized = image.atelierDownscaled(maxDimension: 1400)
        guard let data = resized.jpegData(compressionQuality: 0.86) else { return nil }
        let name = UUID().uuidString + ".jpg"
        let url = imagesDirectory.appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
            return name
        } catch {
            return nil
        }
    }

    private func deleteImage(named name: String) {
        imageCache.removeObject(forKey: name as NSString)
        try? FileManager.default.removeItem(at: imagesDirectory.appendingPathComponent(name))
    }

    // MARK: - Persistenza

    private func load() {
        guard let data = try? Data(contentsOf: dataURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let payload = try? decoder.decode(Payload.self, from: data) else { return }
        garments = payload.garments
        outfits = payload.outfits
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        let payload = Payload(garments: garments, outfits: outfits)
        guard let data = try? encoder.encode(payload) else { return }
        try? data.write(to: dataURL, options: .atomic)
    }

    // MARK: - Guardaroba di esempio

    /// Riempie l'armadio con capi di esempio per esplorare subito i consigli.
    func loadSamples() {
        guard garments.isEmpty else { return }
        let samples: [Garment] = [
            Garment(name: "Camicia bianca in cotone",
                    category: .top,
                    colorHex: "#F5F1E8",
                    pattern: .solid,
                    formality: .smartCasual,
                    seasons: [.spring, .summer, .autumn],
                    warmth: 2,
                    brand: "",
                    notes: "Base versatile, funziona con jeans e pantaloni scuri."),
            Garment(name: "T-shirt bianca",
                    category: .top,
                    colorHex: "#FAF8F3",
                    pattern: .solid,
                    formality: .casual,
                    seasons: [.spring, .summer],
                    warmth: 1),
            Garment(name: "Maglia nera a girocollo",
                    category: .top,
                    colorHex: "#1C1C1B",
                    pattern: .solid,
                    formality: .casual,
                    seasons: [.autumn, .winter],
                    warmth: 3),
            Garment(name: "Maglia beige in lana",
                    category: .top,
                    colorHex: "#D9C6A8",
                    secondColorHex: "#C9B393",
                    pattern: .textured,
                    formality: .smartCasual,
                    seasons: [.autumn, .winter],
                    warmth: 4),
            Garment(name: "Camicia azzurra a righe",
                    category: .top,
                    colorHex: "#A9C3DA",
                    secondColorHex: "#F2F4F6",
                    pattern: .striped,
                    formality: .smartCasual,
                    seasons: [.spring, .summer],
                    warmth: 2),
            Garment(name: "Jeans blu chiaro",
                    category: .bottom,
                    colorHex: "#6E96BC",
                    pattern: .solid,
                    formality: .casual,
                    seasons: [.spring, .autumn, .winter],
                    warmth: 3),
            Garment(name: "Pantalone nero slim",
                    category: .bottom,
                    colorHex: "#1A1A1A",
                    pattern: .solid,
                    formality: .smartCasual,
                    seasons: Set(Season.allCases),
                    warmth: 3),
            Garment(name: "Chino cammello",
                    category: .bottom,
                    colorHex: "#B99B72",
                    pattern: .solid,
                    formality: .casual,
                    seasons: [.spring, .summer, .autumn],
                    warmth: 2),
            Garment(name: "Blazer blu navy",
                    category: .outerwear,
                    colorHex: "#26364F",
                    pattern: .solid,
                    formality: .formal,
                    seasons: Set(Season.allCases),
                    warmth: 3),
            Garment(name: "Trench beige",
                    category: .outerwear,
                    colorHex: "#CBB79B",
                    pattern: .solid,
                    formality: .smartCasual,
                    seasons: [.spring, .autumn],
                    warmth: 3),
            Garment(name: "Sneakers bianche",
                    category: .shoes,
                    colorHex: "#F2F0EA",
                    pattern: .solid,
                    formality: .casual,
                    seasons: Set(Season.allCases),
                    warmth: 1),
            Garment(name: "Mocassini marroni",
                    category: .shoes,
                    colorHex: "#6B4B32",
                    pattern: .solid,
                    formality: .smartCasual,
                    seasons: [.spring, .summer, .autumn],
                    warmth: 2),
            Garment(name: "Cintura nera",
                    category: .accessory,
                    colorHex: "#171717",
                    pattern: .solid,
                    formality: .smartCasual,
                    seasons: Set(Season.allCases),
                    warmth: 1)
        ]
        garments = samples
        persist()
    }
}
