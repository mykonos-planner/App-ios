import SwiftUI

struct OutfitsView: View {
    @EnvironmentObject private var store: WardrobeStore

    @State private var showBuilder = false
    @State private var detailTarget: Outfit?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .bottom, spacing: 16) {
                    ScreenHeader(kicker: "Le tue combinazioni",
                                 title: "Outfit",
                                 subtitle: store.outfits.isEmpty
                                    ? "Nessun outfit salvato"
                                    : "\(store.outfits.count) outfit salvati")
                    Spacer(minLength: 0)
                    Button {
                        showBuilder = true
                    } label: {
                        Label("Nuovo outfit", systemImage: "plus")
                    }
                    .buttonStyle(CTAButtonStyle())
                    .disabled(store.garments.count < 2)
                    .opacity(store.garments.count < 2 ? 0.45 : 1)
                }

                if store.outfits.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 280, maximum: 420), spacing: 16)],
                              alignment: .leading,
                              spacing: 16) {
                        ForEach(store.outfits) { outfit in
                            Button {
                                detailTarget = outfit
                            } label: {
                                OutfitCard(outfit: outfit)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 18)
            .padding(.bottom, 40)
        }
        .background(Palette.ivory.ignoresSafeArea())
        .navigationTitle("")
        .fullScreenCover(isPresented: $showBuilder) {
            OutfitBuilderView()
        }
        .fullScreenCover(item: $detailTarget) { outfit in
            OutfitDetailView(outfitID: outfit.id)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 13) {
            Kicker(text: "Componi")
            Text("Nessun outfit ancora")
                .font(.serif(26))
                .foregroundColor(Palette.ink)
            Text(store.garments.count < 2
                 ? "Aggiungi qualche capo nell'Armadio: poi potrai comporre outfit e salvarli con il loro punteggio."
                 : "Apri il compositore, scegli i capi e guarda il punteggio aggiornarsi in tempo reale mentre la palette prende forma.")
                .font(.sans(13))
                .foregroundColor(Palette.inkSoft)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                showBuilder = true
            } label: {
                Label("Componi un outfit", systemImage: "sparkles")
            }
            .buttonStyle(CTAButtonStyle())
            .disabled(store.garments.count < 2)
            .opacity(store.garments.count < 2 ? 0.45 : 1)
        }
        .frame(maxWidth: 640, alignment: .leading)
        .card(padding: 26)
    }
}

// MARK: - Card outfit

struct OutfitCard: View {
    @EnvironmentObject private var store: WardrobeStore
    let outfit: Outfit

    private var items: [Garment] { store.items(for: outfit) }
    private var evaluation: StyleEvaluation { StyleEngine.score(items) }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .firstTextBaseline) {
                Text(outfit.name)
                    .font(.serif(18, .semibold))
                    .foregroundColor(Palette.ink)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text("\(evaluation.total)")
                    .font(.serif(19, .semibold))
                    .foregroundColor(Palette.olive)
            }

            HStack(spacing: 6) {
                ForEach(Array(items.prefix(5))) { garment in
                    ItemThumb(garment: garment, size: 50)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 6) {
                Text(evaluation.label)
                    .font(.sans(10, .semibold))
                    .foregroundColor(Palette.brass)
                Text("·")
                    .font(.sans(10))
                    .foregroundColor(Palette.inkSoft)
                Text("\(items.count) capi")
                    .font(.sans(10))
                    .foregroundColor(Palette.inkSoft)
                Spacer(minLength: 0)
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: Metrics.corner, style: .continuous)
                .fill(Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.corner, style: .continuous)
                .stroke(Palette.hairline, lineWidth: 1)
        )
        .shadow(color: Palette.ink.opacity(0.04), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Dettaglio outfit

struct OutfitDetailView: View {
    @EnvironmentObject private var store: WardrobeStore
    @Environment(\.dismiss) private var dismiss

    let outfitID: UUID

    @State private var confirmDelete = false

    private var outfit: Outfit? {
        store.outfits.first { $0.id == outfitID }
    }

    private var items: [Garment] {
        guard let outfit else { return [] }
        return store.items(for: outfit)
    }

    private var evaluation: StyleEvaluation {
        StyleEngine.score(items)
    }

    var body: some View {
        ModalScaffold(title: outfit?.name ?? "Outfit",
                      kicker: "Outfit salvato",
                      trailing: AnyView(deleteButton)) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ScorePanel(evaluation: evaluation)
                        .card(padding: 20)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Capi")
                            .font(.serif(20, .semibold))
                            .foregroundColor(Palette.ink)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 130, maximum: 170), spacing: 14)],
                                  alignment: .leading,
                                  spacing: 14) {
                            ForEach(items) { garment in
                                VStack(spacing: 7) {
                                    ItemThumb(garment: garment, size: 124)
                                    Text(garment.name)
                                        .font(.sans(11, .medium))
                                        .foregroundColor(Palette.ink)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 124)
                                }
                            }
                        }
                    }
                    .card(padding: 20)

                    if !evaluation.pairs.isEmpty {
                        VStack(alignment: .leading, spacing: 9) {
                            Text("Abbinamenti")
                                .font(.serif(20, .semibold))
                                .foregroundColor(Palette.ink)
                            ForEach(evaluation.pairs) { pair in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("\(pair.score)")
                                        .font(.sans(11, .semibold))
                                        .foregroundColor(Palette.brass)
                                        .frame(width: 26, alignment: .leading)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(pair.title)
                                            .font(.sans(12, .semibold))
                                            .foregroundColor(Palette.ink)
                                            .lineLimit(1)
                                        Text(pair.text)
                                            .font(.sans(10))
                                            .foregroundColor(Palette.inkSoft)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                        .card(padding: 20)
                    }
                }
                .padding(22)
            }
        }
        .alert("Eliminare questo outfit?", isPresented: $confirmDelete) {
            Button("Elimina", role: .destructive) {
                if let outfit { store.deleteOutfit(outfit) }
                dismiss()
            }
            Button("Annulla", role: .cancel) { }
        }
    }

    private var deleteButton: some View {
        Button {
            confirmDelete = true
        } label: {
            Image(systemName: "trash")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Palette.warning)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Palette.surface))
                .overlay(Circle().stroke(Palette.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
