import SwiftUI

struct WardrobeView: View {
    @EnvironmentObject private var store: WardrobeStore

    @State private var filter: GarmentCategory?
    @State private var search = ""
    @State private var draft: GarmentDraft?
    @State private var detailTarget: Garment?

    private var filteredGarments: [Garment] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return store.garments.filter { garment in
            guard filter == nil || garment.category == filter else { return false }
            guard !query.isEmpty else { return true }
            return garment.name.localizedCaseInsensitiveContains(query)
                || garment.brand.localizedCaseInsensitiveContains(query)
                || garment.rgb.descriptiveName.localizedCaseInsensitiveContains(query)
                || ColorFamily.family(for: garment.rgb).label.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .bottom, spacing: 16) {
                    ScreenHeader(kicker: "Il tuo guardaroba", title: "Armadio", subtitle: subtitleText)
                    Spacer(minLength: 0)
                    Button {
                        draft = GarmentDraft(garment: Garment(name: "",
                                                             category: .top,
                                                             colorHex: ColorFamily.beige.referenceHex))
                    } label: {
                        Label("Nuovo capo", systemImage: "plus")
                    }
                    .buttonStyle(CTAButtonStyle())
                }

                searchField

                if store.garments.isEmpty {
                    emptyState
                } else {
                    filterRow
                    if filteredGarments.isEmpty {
                        Text("Nessun capo corrisponde alla ricerca.")
                            .font(.sans(13))
                            .foregroundColor(Palette.inkSoft)
                            .padding(.top, 8)
                    } else {
                        grid
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 18)
            .padding(.bottom, 40)
        }
        .background(Palette.ivory.ignoresSafeArea())
        .navigationTitle("")
        .sheet(item: $draft) { item in
            GarmentEditorView(garment: item.garment)
        }
        .fullScreenCover(item: $detailTarget) { garment in
            GarmentDetailView(garmentID: garment.id)
        }
    }

    private var subtitleText: String {
        if store.garments.isEmpty { return "Ancora nessun capo" }
        let categories = Set(store.garments.map { $0.category }).count
        return "\(store.garments.count) capi · \(categories) categorie"
    }

    private var searchField: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Palette.inkSoft)
            TextField("Cerca per nome, marca o colore", text: $search)
                .textFieldStyle(.plain)
                .font(.sans(14))
            if !search.isEmpty {
                Button {
                    search = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Palette.inkSoft)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .frame(maxWidth: 440)
        .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Palette.surface))
        .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(Palette.hairline, lineWidth: 1))
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Chip(title: "Tutti (\(store.garments.count))", isSelected: filter == nil) {
                    filter = nil
                }
                ForEach(GarmentCategory.allCases) { category in
                    let count = store.garments.filter { $0.category == category }.count
                    if count > 0 {
                        Chip(title: "\(category.shortTitle) (\(count))", isSelected: filter == category) {
                            filter = category
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var grid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 168, maximum: 250), spacing: 16)],
                  alignment: .leading,
                  spacing: 16) {
            ForEach(filteredGarments) { garment in
                Button {
                    detailTarget = garment
                } label: {
                    GarmentCard(garment: garment)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 14) {
            Kicker(text: "Si parte da qui")
            Text("Il tuo armadio è vuoto")
                .font(.serif(28))
                .foregroundColor(Palette.ink)
            Text("Fotografa un capo con la fotocamera dell'iPad oppure importa una foto dalla libreria. Atelier riconosce il colore, lo classifica e lo usa per consigliarti gli abbinamenti: tutto funziona senza internet.")
                .font(.sans(13))
                .foregroundColor(Palette.inkSoft)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                Button {
                    draft = GarmentDraft(garment: Garment(name: "",
                                                         category: .top,
                                                         colorHex: ColorFamily.beige.referenceHex))
                } label: {
                    Label("Aggiungi il primo capo", systemImage: "camera")
                }
                .buttonStyle(CTAButtonStyle())

                Button {
                    store.loadSamples()
                } label: {
                    Text("Carica un armadio di esempio")
                }
                .buttonStyle(CTAButtonStyle(filled: false))
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: 620, alignment: .leading)
        .card(padding: 26)
        .padding(.top, 6)
    }
}
