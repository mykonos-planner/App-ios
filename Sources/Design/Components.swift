import SwiftUI

// MARK: - Immagine del capo (foto oppure campione di colore)

struct GarmentImageView: View {
    @EnvironmentObject private var store: WardrobeStore
    let garment: Garment

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let image = store.image(for: garment) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    swatch
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
    }

    private var swatch: some View {
        ZStack {
            LinearGradient(colors: [garment.rgb.color.opacity(0.95), garment.rgb.color],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
            if let second = garment.secondRGB {
                LinearGradient(colors: [Color.clear, second.color.opacity(0.85)],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
            }
            Image(systemName: garment.category.iconName)
                .font(.system(size: 30, weight: .light))
                .foregroundColor(garment.rgb.luminance > 0.62 ? Palette.ink.opacity(0.35) : Color.white.opacity(0.55))
        }
    }
}

struct ItemThumb: View {
    let garment: Garment
    var size: CGFloat = 60

    var body: some View {
        GarmentImageView(garment: garment)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Palette.hairline, lineWidth: 1)
            )
    }
}

// MARK: - Card del capo

struct GarmentCard: View {
    let garment: Garment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GarmentImageView(garment: garment)
                .frame(height: 176)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(garment.name)
                    .font(.serif(16, .semibold))
                    .foregroundColor(Palette.ink)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Circle()
                        .fill(garment.rgb.color)
                        .frame(width: 9, height: 9)
                        .overlay(Circle().stroke(Palette.hairline, lineWidth: 0.6))
                    Text(garment.rgb.descriptiveName)
                        .lineLimit(1)
                    Text("·")
                    Text(garment.category.shortTitle)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .font(.sans(11))
                .foregroundColor(Palette.inkSoft)
            }
            .padding(.horizontal, 2)
        }
        .padding(9)
        .background(
            RoundedRectangle(cornerRadius: Metrics.corner, style: .continuous)
                .fill(Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.corner, style: .continuous)
                .stroke(Palette.hairline, lineWidth: 1)
        )
        .shadow(color: Palette.ink.opacity(0.05), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Pannello del punteggio

struct ScorePanel: View {
    let evaluation: StyleEvaluation
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 18) {
                ScoreRing(score: evaluation.total,
                          size: compact ? 92 : 112,
                          lineWidth: compact ? 8 : 10)
                VStack(alignment: .leading, spacing: 5) {
                    Text(evaluation.label)
                        .font(.serif(compact ? 19 : 22, .semibold))
                        .foregroundColor(Palette.ink)
                    Text("Armonia dei colori + coerenza dei capi")
                        .font(.sans(11))
                        .foregroundColor(Palette.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    if evaluation.itemCount > 0 {
                        Text("\(evaluation.itemCount) capi")
                            .font(.sans(10, .semibold))
                            .foregroundColor(Palette.brass)
                    }
                }
                Spacer(minLength: 0)
            }

            VStack(spacing: 11) {
                MetricBar(label: "Colori", value: evaluation.colorScore)
                MetricBar(label: "Coerenza", value: evaluation.styleScore)
            }

            if !evaluation.notes.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(Array(evaluation.notes.enumerated()), id: \.offset) { entry in
                        HStack(alignment: .top, spacing: 7) {
                            Circle()
                                .fill(Palette.brass)
                                .frame(width: 4, height: 4)
                                .padding(.top, 6)
                            Text(entry.element)
                                .font(.sans(11))
                                .foregroundColor(Palette.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(2)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Suggerimenti

struct SuggestionRow: View {
    let suggestion: ItemSuggestion
    var onAdd: () -> Void

    var body: some View {
        HStack(spacing: 11) {
            ItemThumb(garment: suggestion.garment, size: 52)
            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.garment.name)
                    .font(.sans(12, .semibold))
                    .foregroundColor(Palette.ink)
                    .lineLimit(1)
                Text(suggestion.reason)
                    .font(.sans(10))
                    .foregroundColor(Palette.inkSoft)
                    .lineLimit(2)
            }
            Spacer(minLength: 6)
            Text("\(suggestion.score)")
                .font(.sans(12, .semibold))
                .foregroundColor(Palette.olive)
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Palette.surface)
                    .frame(width: 27, height: 27)
                    .background(Circle().fill(Palette.ink))
            }
            .buttonStyle(.plain)
        }
        .padding(9)
        .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Palette.ivory))
        .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(Palette.hairline, lineWidth: 1))
    }
}

struct ColorSuggestionTile: View {
    let suggestion: ColorSuggestion

    var body: some View {
        HStack(spacing: 9) {
            Circle()
                .fill(suggestion.family.referenceRGB.color)
                .frame(width: 24, height: 24)
                .overlay(Circle().stroke(Palette.hairline, lineWidth: 1))
            VStack(alignment: .leading, spacing: 1) {
                Text(suggestion.title)
                    .font(.sans(12, .semibold))
                    .foregroundColor(Palette.ink)
                    .lineLimit(1)
                Text(suggestion.reason)
                    .font(.sans(10))
                    .foregroundColor(Palette.inkSoft)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Text("\(suggestion.score)")
                .font(.sans(10, .semibold))
                .foregroundColor(Palette.brass)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Palette.ivory))
        .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(Palette.hairline, lineWidth: 1))
    }
}

// MARK: - Selettore capo

struct GarmentPickerSheet: View {
    @EnvironmentObject private var store: WardrobeStore
    @Environment(\.dismiss) private var dismiss

    var excludedIDs: Set<UUID> = []
    var onPick: (Garment) -> Void

    @State private var filter: GarmentCategory?

    private var visibleGarments: [Garment] {
        store.garments.filter { garment in
            !excludedIDs.contains(garment.id) && (filter == nil || garment.category == filter)
        }
    }

    var body: some View {
        ModalScaffold(title: "Aggiungi un capo", kicker: "Armadio") {
            VStack(alignment: .leading, spacing: 14) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Chip(title: "Tutti", isSelected: filter == nil) { filter = nil }
                        ForEach(GarmentCategory.allCases) { category in
                            if store.garments.contains(where: { $0.category == category }) {
                                Chip(title: category.shortTitle, isSelected: filter == category) {
                                    filter = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                }

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 130, maximum: 170), spacing: 14)],
                              alignment: .leading,
                              spacing: 14) {
                        ForEach(visibleGarments) { garment in
                            Button {
                                onPick(garment)
                                dismiss()
                            } label: {
                                VStack(spacing: 7) {
                                    ItemThumb(garment: garment, size: 120)
                                    Text(garment.name)
                                        .font(.sans(11, .medium))
                                        .foregroundColor(Palette.ink)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 120)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 24)
                }
            }
            .padding(.top, 14)
        }
    }
}
