import Foundation

// MARK: - Risultati

struct PairNote: Identifiable {
    let id = UUID()
    let title: String
    let score: Int
    let text: String
}

struct StyleEvaluation {
    var colorScore: Int = 0
    var styleScore: Int = 0
    var total: Int = 0
    var label: String = "Aggiungi capi"
    var notes: [String] = []
    var pairs: [PairNote] = []
    var itemCount: Int = 0
}

struct ItemSuggestion: Identifiable {
    let id: UUID
    let garment: Garment
    let score: Int
    let reason: String
}

struct ColorSuggestion: Identifiable {
    let id: String
    let family: ColorFamily
    let title: String
    let score: Int
    let reason: String
}

struct OutfitIdea: Identifiable {
    let id: UUID
    let items: [Garment]
    let evaluation: StyleEvaluation
}

// MARK: - Motore di stile

enum StyleEngine {

    // MARK: Armonia tra due colori

    static func hueDistance(_ a: Double, _ b: Double) -> Double {
        let raw = abs(a - b).truncatingRemainder(dividingBy: 360)
        let distance = raw > 180 ? 360 - raw : raw
        return distance
    }

    /// Punteggio 0-100 per una coppia di colori, con spiegazione in italiano.
    static func pairScore(_ a: RGBColor, _ b: RGBColor) -> (score: Int, text: String) {
        let familyA = ColorFamily.family(for: a)
        let familyB = ColorFamily.family(for: b)
        let hslA = a.hsl
        let hslB = b.hsl

        if familyA == familyB {
            if familyA.isNeutral {
                let delta = abs(hslA.l - hslB.l)
                if delta < 0.08 { return (72, "Stesso neutro e stesso tono: pulito, ma un po' piatto.") }
                return (94, "Neutri su toni diversi: eleganza garantita.") }
            if abs(hslA.l - hslB.l) > 0.22 { return (85, "Monocromatico con contrasto: molto raffinato.") }
            return (70, "Toni troppo vicini: serve un neutro a fare da pausa.")
        }

        if familyA.isNeutral || familyB.isNeutral {
            return (90, "Neutro con colore: abbinamento sempre riuscito.")
        }

        let distance = hueDistance(hslA.h, hslB.h)
        let loud = min(hslA.s, hslB.s) > 0.42

        if distance < 22 { return (84, "Toni analoghi: armonia morbida.") }
        if distance < 48 {
            return loud
                ? (64, "Toni vicini e accesi: rischiano di competere.")
                : (80, "Toni analoghi: armonia morbida.")
        }
        if distance < 95 {
            return loud
                ? (46, "Colori che litigano: smorzane uno dei due con un neutro.")
                : (71, "Accostamento deciso ma controllato.")
        }
        if distance < 135 { return (73, "Tricromia: vivace e bilanciata.") }
        if distance < 168 { return (79, "Split complementare: contrasto sofisticato.") }
        return (75, "Complementari: contrasto d'impatto.")
    }

    /// Come sopra, ma considerando anche l'eventuale secondo colore (fantasie).
    static func garmentPairScore(_ a: Garment, _ b: Garment) -> (score: Int, text: String) {
        var total = 0.0
        var count = 0.0
        var best = (score: 0, text: "")
        for colorA in a.palette {
            for colorB in b.palette {
                let result = pairScore(colorA, colorB)
                total += Double(result.score)
                count += 1
                if result.score > best.score { best = result }
            }
        }
        guard count > 0 else { return (0, "") }
        return (Int((total / count).rounded()), best.text)
    }

    static func weight(for category: GarmentCategory) -> Double {
        switch category {
        case .top, .bottom, .dress: return 1.0
        case .outerwear: return 0.85
        case .shoes: return 0.8
        case .accessory: return 0.5
        }
    }

    // MARK: Valutazione completa

    static func score(_ items: [Garment]) -> StyleEvaluation {
        var evaluation = StyleEvaluation()
        evaluation.itemCount = items.count
        guard !items.isEmpty else { return evaluation }

        // --- Armonia dei colori
        var weightedSum = 0.0
        var totalWeight = 0.0
        if items.count > 1 {
            for i in 0..<items.count {
                for j in (i + 1)..<items.count {
                    let first = items[i]
                    let second = items[j]
                    let pair = garmentPairScore(first, second)
                    let weight = self.weight(for: first.category) * self.weight(for: second.category)
                    weightedSum += Double(pair.score) * weight
                    totalWeight += weight
                    evaluation.pairs.append(PairNote(title: "\(first.name) + \(second.name)",
                                                     score: pair.score,
                                                     text: pair.text))
                }
            }
        }
        evaluation.colorScore = totalWeight > 0 ? Int((weightedSum / totalWeight).rounded()) : 100

        // --- Coerenza (struttura, occasioni, fantasie, stagioni)
        let categories = Set(items.map { $0.category })
        var completeness = 0.0
        if categories.contains(.dress) {
            completeness += 0.55
        } else {
            if categories.contains(.top) { completeness += 0.30 }
            if categories.contains(.bottom) { completeness += 0.30 }
        }
        if categories.contains(.shoes) { completeness += 0.20 }
        if categories.contains(.outerwear) { completeness += 0.05 }
        if categories.contains(.accessory) { completeness += 0.05 }
        completeness = min(completeness, 1.0)

        var style = 40.0 + completeness * 45.0

        let ranks = items.map { $0.formality.rank }
        let spread = (ranks.max() ?? 0) - (ranks.min() ?? 0)
        if items.count > 1 {
            if spread == 0 {
                style += 8
            } else if spread >= 2 {
                style -= 14
            } else {
                style -= 3
            }
        }

        let patterned = items.filter { $0.pattern != .solid }
        switch patterned.count {
        case 0: style += 4
        case 1: style += 2
        case 2: style -= 14
        default: style -= 22
        }

        var commonSeasons = items.first?.seasons ?? []
        for item in items.dropFirst() {
            commonSeasons = commonSeasons.intersection(item.seasons)
        }
        if commonSeasons.isEmpty && items.count > 1 { style -= 9 } else { style += 4 }

        if items.count > 1 && items.allSatisfy({ ColorFamily.family(for: $0.rgb).isNeutral }) {
            style -= 2
        }

        style = min(max(style, 0), 100)
        evaluation.styleScore = Int(style.rounded())
        var total = Int((0.66 * Double(evaluation.colorScore) + 0.34 * style).rounded())
        if items.count == 1 { total = min(total, 58) }
        evaluation.total = min(max(total, 0), 100)
        evaluation.label = label(for: evaluation.total)

        // --- Spiegazioni
        var notes: [String] = []
        if items.count == 1 {
            notes.append("Un solo capo: aggiungi almeno un altro pezzo per valutare l'abbinamento.")
        }
        if (categories.contains(.top) && categories.contains(.bottom)) || categories.contains(.dress) {
            notes.append("Struttura completa: c'è una base solida.")
        } else if items.count > 1 {
            let missing = missingSlots(categories)
            if !missing.isEmpty {
                notes.append("Manca una parte dell'outfit: aggiungi " + missing.joined(separator: " o ") + ".")
            }
        }
        if items.count > 1 {
            if spread >= 2 {
                notes.append("Registri troppo distanti (sportivo vs elegante): sostituisci un capo con uno più coerente.")
            } else if spread == 0 {
                notes.append("Stesso registro formale: outfit coerente.")
            }
        }
        if patterned.count >= 2 {
            notes.append("Più fantasie insieme: lascia una sola stampa e il resto tinta unita.")
        }
        if commonSeasons.isEmpty && items.count > 1 {
            notes.append("Stagioni non compatibili: questi capi non si incontrano in nessun periodo.")
        }
        if items.count > 1 && items.allSatisfy({ ColorFamily.family(for: $0.rgb).isNeutral }) {
            notes.append("Palette di soli neutri: raffinata, ma un tocco di colore la renderebbe più viva.")
        }
        if let best = evaluation.pairs.max(by: { $0.score < $1.score }) {
            notes.append("Il migliore: \(best.title) — \(best.text)")
        }
        if let worst = evaluation.pairs.min(by: { $0.score < $1.score }), worst.score < 60 {
            notes.append("Da rivedere: \(worst.title) — \(worst.text)")
        }
        evaluation.notes = notes
        return evaluation
    }

    static func missingSlots(_ categories: Set<GarmentCategory>) -> [String] {
        var missing: [String] = []
        if !categories.contains(.dress) {
            if !categories.contains(.top) { missing.append("una parte superiore") }
            if !categories.contains(.bottom) { missing.append("una parte inferiore") }
        }
        if !categories.contains(.shoes) { missing.append("un paio di scarpe") }
        return missing
    }

    static func label(for score: Int) -> String {
        switch score {
        case 90...: return "Armonioso"
        case 80..<90: return "Molto buono"
        case 68..<80: return "Buono"
        case 55..<68: return "Da sistemare"
        default: return "Da rivedere"
        }
    }

    // MARK: Suggerimenti dai capi che possiedi

    static func itemSuggestions(base: [Garment], pool: [Garment], limit: Int = 6) -> [ItemSuggestion] {
        let baseIDs = Set(base.map { $0.id })
        let taken = Set(base.map { $0.category })
        let baseEvaluation = score(base)

        var results: [ItemSuggestion] = []
        for candidate in pool where !baseIDs.contains(candidate.id) {
            if candidate.category != .accessory && taken.contains(candidate.category) { continue }
            if candidate.category == .dress && (taken.contains(.top) || taken.contains(.bottom) || taken.contains(.dress)) { continue }
            if taken.contains(.dress) && (candidate.category == .top || candidate.category == .bottom) { continue }

            let trial = score(base + [candidate])
            var reason = base.isEmpty ? "Un buon punto di partenza." : "Completa bene la selezione."
            var bestPair = 0
            for item in base {
                let pair = garmentPairScore(item, candidate)
                if pair.score > bestPair {
                    bestPair = pair.score
                    reason = pair.text
                }
            }
            results.append(ItemSuggestion(id: candidate.id,
                                          garment: candidate,
                                          score: trial.total,
                                          reason: reason))
        }

        results.sort { $0.score > $1.score }
        return Array(results.prefix(limit))
    }

    // MARK: Suggerimenti di colore (anche senza avere il capo)

    static func colorSuggestions(base: [Garment], categories: [GarmentCategory], limit: Int = 9) -> [ColorSuggestion] {
        guard !categories.isEmpty else { return [] }
        let averageRank: Double
        if base.isEmpty {
            averageRank = 1.0
        } else {
            let sum = base.map { $0.formality.rank }.reduce(0, +)
            averageRank = Double(sum) / Double(base.count)
        }

        var perCategory: [[ColorSuggestion]] = []
        for category in categories.prefix(2) {
            var options: [ColorSuggestion] = []
            for family in ColorFamily.allCases {
                let reference = family.referenceRGB
                var total = 0.0
                var count = 0.0
                for item in base {
                    for color in item.palette {
                        total += Double(pairScore(reference, color).score)
                        count += 1
                    }
                }
                var value = count > 0 ? total / count : 78.0
                if family.isNeutral { value += 6 }
                if averageRank >= 2.0 && !family.isNeutral { value -= 10 }
                if averageRank >= 2.5 && family.isNeutral { value += 3 }
                if family == .navy { value += 3 }

                let finalScore = Int(min(max(value, 0), 100).rounded())
                let title = category.noun.capitalizedFirst + " " + family.adjective(for: category.gender)
                var reason = family.isNeutral
                    ? "Neutro versatile: funziona con quasi tutto."
                    : "Tono \(family.label.lowercased()) in armonia con la palette."
                if let match = base.first(where: { item in
                    item.palette.contains(where: { pairScore(reference, $0).score >= 80 })
                }) {
                    reason = "Sta bene con \(match.name.lowercased())."
                }
                options.append(ColorSuggestion(id: "\(category.rawValue)-\(family.rawValue)",
                                               family: family,
                                               title: title,
                                               score: finalScore,
                                               reason: reason))
            }
            options.sort { $0.score > $1.score }
            perCategory.append(Array(options.prefix(3)))
        }

        let flattened = perCategory.flatMap { $0 }
        return Array(flattened.prefix(limit))
    }

    // MARK: Idee di outfit complete

    static func outfitIdeas(pool: [Garment], limit: Int = 8) -> [OutfitIdea] {
        let tops = pool.filter { $0.category == .top }
        let bottoms = pool.filter { $0.category == .bottom }
        let dresses = pool.filter { $0.category == .dress }
        let shoes = pool.filter { $0.category == .shoes }
        let outerwear = pool.filter { $0.category == .outerwear }

        func bestMatch(in candidates: [Garment], for items: [Garment]) -> Garment? {
            guard !candidates.isEmpty else { return nil }
            var bestItem: Garment?
            var bestScore = -1
            for candidate in candidates where !items.contains(where: { $0.id == candidate.id }) {
                let value = score(items + [candidate]).total
                if value > bestScore {
                    bestScore = value
                    bestItem = candidate
                }
            }
            return bestItem
        }

        var combinations: [[Garment]] = []
        for bottom in bottoms.prefix(12) {
            for top in tops.prefix(12) {
                var items = [top, bottom]
                if let shoe = bestMatch(in: shoes, for: items) { items.append(shoe) }
                if let jacket = bestMatch(in: outerwear, for: items) { items.append(jacket) }
                combinations.append(items)
            }
        }
        for dress in dresses.prefix(12) {
            var items = [dress]
            if let shoe = bestMatch(in: shoes, for: items) { items.append(shoe) }
            if let jacket = bestMatch(in: outerwear, for: items) { items.append(jacket) }
            combinations.append(items)
        }

        var seen = Set<String>()
        var ideas: [OutfitIdea] = []
        for combination in combinations {
            let key = combination.map { $0.id.uuidString }.sorted().joined(separator: "|")
            if seen.contains(key) { continue }
            seen.insert(key)
            ideas.append(OutfitIdea(id: UUID(), items: combination, evaluation: score(combination)))
        }
        ideas.sort { $0.evaluation.total > $1.evaluation.total }
        return Array(ideas.prefix(limit))
    }
}
