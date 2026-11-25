import SwiftUI

struct RootView: View {
    @State private var selection: AppSection? = .wardrobe

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
        } detail: {
            NavigationStack {
                VStack(spacing: 0) {
                    switch selection ?? .wardrobe {
                    case .wardrobe:
                        WardrobeView()
                    case .outfits:
                        OutfitsView()
                    case .advisor:
                        AdvisorView()
                    }
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .tint(Palette.brass)
    }
}

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case wardrobe
    case outfits
    case advisor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wardrobe: return "Armadio"
        case .outfits: return "Outfit"
        case .advisor: return "Consigli"
        }
    }

    var icon: String {
        switch self {
        case .wardrobe: return "square.grid.2x2"
        case .outfits: return "square.stack"
        case .advisor: return "sparkles"
        }
    }
}

struct SidebarView: View {
    @Binding var selection: AppSection?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 3) {
                Text("ATELIER")
                    .font(.serif(22, .semibold))
                    .tracking(3)
                    .foregroundColor(Palette.ink)
                Text("Il tuo guardaroba, in ordine.")
                    .font(.sans(11))
                    .foregroundColor(Palette.inkSoft)
            }
            .padding(.horizontal, 20)
            .padding(.top, 26)
            .padding(.bottom, 18)

            ForEach(AppSection.allCases) { section in
                Button {
                    selection = section
                } label: {
                    HStack(spacing: 11) {
                        Image(systemName: section.icon)
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 22)
                        Text(section.title)
                            .font(.sans(15, .medium))
                        Spacer(minLength: 0)
                    }
                    .foregroundColor(selection == section ? Palette.surface : Palette.ink)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(selection == section ? Palette.ink : Color.clear)
                    )
                    .padding(.horizontal, 10)
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 4) {
                Text("100% offline")
                    .font(.sans(10, .semibold))
                    .foregroundColor(Palette.brass)
                Text("Foto e outfit restano su questo iPad: nessun dato lascia il dispositivo.")
                    .font(.sans(10))
                    .foregroundColor(Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.ivory)
        .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 290)
    }
}
