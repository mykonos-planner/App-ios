import SwiftUI

struct AdvisorView: View {
    @EnvironmentObject private var store: WardrobeStore

    enum Mode: String, CaseIterable, Identifiable {
        case coach
        case ideas

        var id: String { rawValue }

        var title: String {
            switch self {
            case .coach: return "Da un capo"
            case .ideas: return "Idee pronte"
            }
        }
    }

    @State private var selection: [Garment]
    @State private var mode: Mode = .coach
    @State private var showPicker = false
    @State private var ideas: [OutfitIdea] = []
    @State private var savedKeys: Set<String> = []

    init(seed: [Garment] = []) {
        _selection = State(initialValue: seed)
    }

    private var evaluation: StyleEvaluation {
        StyleEngine.score(selection)
    }

    private var missingCategories: [GarmentCategory] {
        let taken = Set(selection.map { $0.category })
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
        StyleEngine.itemSuggestions(base: selection, pool: store.garments, limit: 6)
    }

    private var colorIdeas: [ColorSuggestion] {
        StyleEngine.colorSuggestions(base: selection, categories: missingCategories, limit: 9)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .bottom, spacing: 16) {
                    ScreenHeader(kicker: "Il motore di stile",
                                 title: "Consigli",
                                 subtitle: "Abbinamenti e punteggi calcolati sul dispositivo, senza internet")
                    Spacer(minLength: 0)
                    Picker("Modalità", selection: $mode) {
                        ForEach(Mode.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 260)
                }

                if mode == .coach {
                    coachContent
                } else {
                    ideasContent
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 18)
            .padding(.bottom, 40)
        }
        .background(Palette.ivory.ignoresSafeArea())
        .navigationTitle("")
        .onAppear {
            if ideas.isEmpty { regenerateIdeas() }
        }
        .onChange(of: mode) { newMode in
            if newMode == .ideas && ideas.isEmpty { regenerateIdeas() }
        }
        .onChange(of: store.garments.count) { _ in
            if mode == .ideas { regenerateIdeas() } else { ideas = [] }
        }
        .sheet(isPresented: $showPicker) {
            GarmentPickerSheet(excludedIDs: Set(selection.map { $0.id })) { garment in
                selection.append(garment)
            }
        }
    }

    // MARK: Modalità "da un capo"

    @ViewBuilder
    private var coachContent: some View {
        if selection.isEmpty {
            startPicker
        } else {
            selectionTray
            HStack(alignment: .top, spacing: 18) {
                ScorePanel(evaluation: evaluation)
                    .card(padding: 20)
                    .frame(maxWidth: 380)
                VStack(alignment: .leading, spacing: 16) {
                    suggestionsBlock
                    colorsBlock
                }
            }
        }
    }

    private var startPicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Da quale capo partiamo?")
                .font(.serif(24))
                .foregroundColor(Palette.ink)
            Text("Scegli un capo del tuo armadio: Atelier ti dice cosa ci sta bene secondo i colori e la coerenza dello stile. Ad esempio, con un paio di jeans blu chiaro vedrai arrivare le proposte di maglie bianche, nere o beige.")
                .font(.sans(13))
                .foregroundColor(Palette.inkSoft)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if store.garments.isEmpty {
                Text("L'armadio è ancora vuoto: aggiungi qualche capo dalla sezione Armadio.")
                    .font(.sans(13))
                    .foregroundColor(Palette.inkSoft)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 190), spacing: 14)],
                          alignment: .leading,
                          spacing: 14) {
                    ForEach(store.garments) { garment in
                        Button {
                            selection = [garment]
                        } label: {
                            VStack(spacing: 7) {
                                ItemThumb(garment: garment, size: 128)
                                Text(garment.name)
                                    .font(.sans(11, .medium))
                                    .foregroundColor(Palette.ink)
                                    .lineLimit(1)
                                    .frame(width: 128)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .card(padding: 22)
    }

    private var selectionTray: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("La tua selezione")
                    .font(.serif(20, .semibold))
                    .foregroundColor(Palette.ink)
                Spacer()
                Button {
                    showPicker = true
                } label: {
                    Label("Aggiungi", systemImage: "plus")
                }
                .buttonStyle(CTAButtonStyle(filled: false))
                Button {
                    selection.removeAll()
                } label: {
                    Text("Svuota")
                }
                .buttonStyle(CTAButtonStyle(filled: false))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(selection) { garment in
                        VStack(spacing: 6) {
                            ZStack(alignment: .topTrailing) {
                                ItemThumb(garment: garment, size: 96)
                                Button {
                                    selection.removeAll { $0.id == garment.id }
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
                                .frame(width: 96)
                        }
                    }
                }
                .padding(.top, 5)
            }
        }
        .card(padding: 18)
    }

    private var suggestionsBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Dall'armadio")
                    .font(.serif(19, .semibold))
                    .foregroundColor(Palette.ink)
                Spacer()
                Text("\(suggestions.count) proposte")
                    .font(.sans(10))
                    .foregroundColor(Palette.inkSoft)
            }
            if suggestions.isEmpty {
                Text("Aggiungi altri capi all'armadio per ricevere suggerimenti.")
                    .font(.sans(11))
                    .foregroundColor(Palette.inkSoft)
            } else {
                ForEach(suggestions) { suggestion in
                    SuggestionRow(suggestion: suggestion) {
                        selection.append(suggestion.garment)
                    }
                }
            }
        }
        .card()
    }

    private var colorsBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Colori che funzionano")
                .font(.serif(19, .semibold))
                .foregroundColor(Palette.ink)
            Text("Se dovessi cercare un capo nuovo, questi sono i colori che si sposano con la selezione.")
                .font(.sans(11))
                .foregroundColor(Palette.inkSoft)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            if !colorIdeas.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 8)],
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

    // MARK: Modalità "idee pronte"

    private var ideasContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Combinazioni generate")
                        .font(.serif(22))
                        .foregroundColor(Palette.ink)
                    Text("Atelier prova le combinazioni del tuo armadio e tiene le migliori per colore e coerenza.")
                        .font(.sans(12))
                        .foregroundColor(Palette.inkSoft)
                }
                Spacer(minLength: 12)
                Button {
                    regenerateIdeas()
                } label: {
                    Label("Ricalcola", systemImage: "arrow.clockwise")
                }
                .buttonStyle(CTAButtonStyle(filled: false))
            }

            if store.garments.count < 2 {
                Text("Servono almeno due capi nell'armadio per generare delle idee.")
                    .font(.sans(13))
                    .foregroundColor(Palette.inkSoft)
            } else if ideas.isEmpty {
                Text("Nessuna combinazione completa: aggiungi una parte superiore e una inferiore (o un vestito).")
                    .font(.sans(13))
                    .foregroundColor(Palette.inkSoft)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300, maximum: 420), spacing: 16)],
                          alignment: .leading,
                          spacing: 16) {
                    ForEach(ideas) { idea in
                        IdeaCard(idea: idea,
                                 isSaved: savedKeys.contains(key(for: idea)),
                                 onSave: { save(idea) })
                    }
                }
            }
        }
    }

    private func regenerateIdeas() {
        ideas = StyleEngine.outfitIdeas(pool: store.garments, limit: 8)
        savedKeys = []
    }

    private func key(for idea: OutfitIdea) -> String {
        idea.items.map { $0.id.uuidString }.sorted().joined(separator: "|")
    }

    private func save(_ idea: OutfitIdea) {
        let ideaKey = key(for: idea)
        guard !savedKeys.contains(ideaKey) else { return }
        let outfit = Outfit(name: "Completo \(store.outfits.count + 1)",
                            itemIDs: idea.items.map { $0.id },
                            savedScore: idea.evaluation.total)
        store.saveOutfit(outfit)
        savedKeys.insert(ideaKey)
    }
}

// MARK: - Card idea

struct IdeaCard: View {
    let idea: OutfitIdea
    let isSaved: Bool
    var onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(idea.evaluation.label)
                    .font(.sans(10, .semibold))
                    .foregroundColor(Palette.brass)
                Spacer(minLength: 8)
                Text("\(idea.evaluation.total)")
                    .font(.serif(20, .semibold))
                    .foregroundColor(Palette.ink)
            }

            HStack(spacing: 6) {
                ForEach(idea.items) { garment in
                    ItemThumb(garment: garment, size: 56)
                }
                Spacer(minLength: 0)
            }

            Text(idea.items.map { $0.name }.joined(separator: " · "))
                .font(.sans(10))
                .foregroundColor(Palette.inkSoft)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onSave) {
                Text(isSaved ? "Salvato" : "Salva outfit")
            }
            .buttonStyle(CTAButtonStyle(filled: !isSaved))
            .disabled(isSaved)
        }
        .card(padding: 15)
    }
}
