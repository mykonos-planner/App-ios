import SwiftUI

struct OutfitBuilderView: View {
    @EnvironmentObject private var store: WardrobeStore
    @Environment(\.dismiss) private var dismiss

    @State private var items: [Garment] = []
    @State private var showPicker = false
    @State private var showSave = false
    @State private var outfitName = ""

    private var evaluation: StyleEvaluation {
        StyleEngine.score(items)
    }

    private var missingCategories: [GarmentCategory] {
        let taken = Set(items.map { $0.category })
        if taken.contains(.dress) {
            return [.outerwear, .shoes].filter { !taken.contains($0) }
        }
        var result: [GarmentCategory] = []
        if !taken.contains(.top) { result.append(.top) }
        if !taken.contains(.bottom) { result.append(.bottom) }
        if !taken.contains(.shoes) { result.append(.shoes) }
        if !taken.contains(.outerwear) { result.append(.outerwear) }
        if result.isEmpty { result.append(.accessory) }
        return result
    }

    private var suggestions: [ItemSuggestion] {
        StyleEngine.itemSuggestions(base: items, pool: store.garments, limit: 6)
    }

    private var colorIdeas: [ColorSuggestion] {
        StyleEngine.colorSuggestions(base: items, categories: missingCategories, limit: 9)
    }

    var body: some View {
        ModalScaffold(title: "Nuovo outfit",
                      kicker: "Componi",
                      trailing: AnyView(saveButton)) {
            GeometryReader { geometry in
                ScrollView {
                    if geometry.size.width > 900 {
                        HStack(alignment: .top, spacing: 20) {
                            mainColumn
                            sideColumn.frame(width: 360)
                        }
                        .padding(22)
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            mainColumn
                            sideColumn
                        }
                        .padding(18)
                    }
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            GarmentPickerSheet(excludedIDs: Set(items.map { $0.id })) { garment in
                items.append(garment)
            }
        }
        .alert("Salva outfit", isPresented: $showSave) {
            TextField("Nome", text: $outfitName)
            Button("Salva") { commitSave() }
            Button("Annulla", role: .cancel) { }
        } message: {
            Text("Dai un nome alla combinazione per ritrovarla nell'elenco.")
        }
    }

    private var saveButton: some View {
        Button {
            outfitName = "Outfit \(store.outfits.count + 1)"
            showSave = true
        } label: {
            Text("Salva outfit")
        }
        .buttonStyle(CTAButtonStyle())
        .disabled(items.count < 2)
        .opacity(items.count < 2 ? 0.45 : 1)
    }

    // MARK: Colonne

    private var mainColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            selectionCard
            ScorePanel(evaluation: evaluation).card(padding: 20)
        }
    }

    private var sideColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            suggestionsCard
            colorsCard
        }
    }

    private var selectionCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text("Capi scelti")
                    .font(.serif(20, .semibold))
                    .foregroundColor(Palette.ink)
                Spacer()
                Text("\(items.count)")
                    .font(.sans(11, .semibold))
                    .foregroundColor(Palette.brass)
            }

            if items.isEmpty {
                Text("Aggiungi i capi uno alla volta: il punteggio si aggiorna in tempo reale e ti dice subito se l'abbinamento funziona.")
                    .font(.sans(12))
                    .foregroundColor(Palette.inkSoft)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 116, maximum: 150), spacing: 12)],
                          alignment: .leading,
                          spacing: 12) {
                    ForEach(items) { garment in
                        selectedTile(garment)
                    }
                }
            }

            HStack(spacing: 9) {
                Button {
                    showPicker = true
                } label: {
                    Label("Aggiungi capo", systemImage: "plus")
                }
                .buttonStyle(CTAButtonStyle(filled: false))

                if !items.isEmpty {
                    Button {
                        items.removeAll()
                    } label: {
                        Text("Svuota")
                    }
                    .buttonStyle(CTAButtonStyle(filled: false))
                }
            }
        }
        .card(padding: 20)
    }

    private func selectedTile(_ garment: Garment) -> some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                ItemThumb(garment: garment, size: 114)
                Button {
                    items.removeAll { $0.id == garment.id }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Palette.surface)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Palette.ink))
                }
                .buttonStyle(.plain)
                .offset(x: 5, y: -5)
            }
            Text(garment.name)
                .font(.sans(10))
                .foregroundColor(Palette.inkSoft)
                .lineLimit(1)
                .frame(width: 114)
        }
    }

    private var suggestionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Dall'armadio")
                    .font(.serif(19, .semibold))
                    .foregroundColor(Palette.ink)
                Spacer()
                Text("\(suggestions.count)")
                    .font(.sans(10, .semibold))
                    .foregroundColor(Palette.brass)
            }
            if suggestions.isEmpty {
                Text("Aggiungi capi all'armadio per ricevere suggerimenti sugli abbinamenti.")
                    .font(.sans(11))
                    .foregroundColor(Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(suggestions) { suggestion in
                    SuggestionRow(suggestion: suggestion) {
                        items.append(suggestion.garment)
                    }
                }
            }
        }
        .card()
    }

    private var colorsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Colori che funzionano")
                .font(.serif(19, .semibold))
                .foregroundColor(Palette.ink)
            Text(items.isEmpty
                 ? "Parti da un capo: qui vedrai i colori che si sposano meglio con la selezione."
                 : "Cosa cercare per completare l'outfit, anche se non è ancora nel tuo armadio.")
                .font(.sans(11))
                .foregroundColor(Palette.inkSoft)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            if !colorIdeas.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 8)],
                          alignment: .leading,
                          spacing: 8) {
                    ForEach(colorIdeas) { idea in
                        ColorSuggestionTile(suggestion: idea)
                    }
                }
            }
        }
        .card()
    }

    // MARK: Salvataggio

    private func commitSave() {
        let trimmed = outfitName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmed.isEmpty ? "Outfit \(store.outfits.count + 1)" : trimmed
        let outfit = Outfit(name: finalName,
                            itemIDs: items.map { $0.id },
                            savedScore: evaluation.total)
        store.saveOutfit(outfit)
        dismiss()
    }
}
