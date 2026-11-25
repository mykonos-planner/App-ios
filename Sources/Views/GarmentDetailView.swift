import SwiftUI

struct GarmentDetailView: View {
    @EnvironmentObject private var store: WardrobeStore
    @Environment(\.dismiss) private var dismiss

    let garmentID: UUID

    @State private var showEditor = false
    @State private var showAdvice = false
    @State private var confirmDelete = false

    var body: some View {
        ZStack {
            Palette.ivory.ignoresSafeArea()

            if let garment = store.garment(with: garmentID) {
                VStack(spacing: 0) {
                    header(garment)
                    Divider().overlay(Palette.hairline)
                    ScrollView {
                        HStack(alignment: .top, spacing: 26) {
                            photo(garment)
                            info(garment)
                        }
                        .padding(26)
                    }
                }
            } else {
                Text("Questo capo non è più nel tuo armadio.")
                    .font(.sans(14))
                    .foregroundColor(Palette.inkSoft)
            }
        }
        .sheet(isPresented: $showEditor) {
            if let garment = store.garment(with: garmentID) {
                GarmentEditorView(garment: garment)
            }
        }
        .fullScreenCover(isPresented: $showAdvice) {
            if let garment = store.garment(with: garmentID) {
                NavigationStack {
                    AdvisorView(seed: [garment])
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Chiudi") { showAdvice = false }
                            }
                        }
                }
            }
        }
        .alert("Eliminare questo capo?", isPresented: $confirmDelete) {
            Button("Elimina", role: .destructive) {
                if let garment = store.garment(with: garmentID) {
                    store.delete(garment)
                }
                dismiss()
            }
            Button("Annulla", role: .cancel) { }
        } message: {
            Text("Verrà rimosso anche dagli outfit che lo contengono.")
        }
    }

    private func header(_ garment: Garment) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(garment.category.title.uppercased())
                    .font(.sans(9, .semibold))
                    .tracking(1.6)
                    .foregroundColor(Palette.brass)
                Text(garment.name)
                    .font(.serif(26, .semibold))
                    .foregroundColor(Palette.ink)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Button {
                showAdvice = true
            } label: {
                Label("Cosa ci sta bene", systemImage: "sparkles")
            }
            .buttonStyle(CTAButtonStyle())

            CircleIconButton(icon: "pencil") { showEditor = true }

            Menu {
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Label("Elimina capo", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Palette.ink)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Palette.surface))
                    .overlay(Circle().stroke(Palette.hairline, lineWidth: 1))
            }

            CircleIconButton(icon: "xmark") { dismiss() }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 15)
    }

    private func photo(_ garment: Garment) -> some View {
        GarmentImageView(garment: garment)
            .frame(width: 400, height: 470)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Palette.hairline, lineWidth: 1)
            )
    }

    private func info(_ garment: Garment) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            if !garment.brand.isEmpty {
                Text(garment.brand)
                    .font(.sans(13, .medium))
                    .foregroundColor(Palette.inkSoft)
            }

            HStack(spacing: 8) {
                colorPill(garment.rgb)
                if let second = garment.secondRGB {
                    colorPill(second)
                }
            }

            VStack(spacing: 11) {
                DetailRow(label: "Categoria", value: garment.category.title)
                Divider().overlay(Palette.hairline)
                DetailRow(label: "Fantasia", value: garment.pattern.title)
                Divider().overlay(Palette.hairline)
                DetailRow(label: "Occasione", value: garment.formality.title)
                Divider().overlay(Palette.hairline)
                DetailRow(label: "Stagioni", value: garment.seasonText)
                Divider().overlay(Palette.hairline)
                DetailRow(label: "Calore", value: garment.warmthText)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.surface))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Palette.hairline, lineWidth: 1))

            if !garment.notes.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    FieldLabel(text: "Note")
                    Text(garment.notes)
                        .font(.sans(13))
                        .foregroundColor(Palette.ink)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button {
                showAdvice = true
            } label: {
                Label("Scopri cosa ci sta bene", systemImage: "wand.and.stars")
            }
            .buttonStyle(CTAButtonStyle(filled: false))

            Spacer(minLength: 0)
        }
        .frame(maxWidth: 420, alignment: .leading)
    }

    private func colorPill(_ color: RGBColor) -> some View {
        HStack(spacing: 7) {
            Circle()
                .fill(color.color)
                .frame(width: 18, height: 18)
                .overlay(Circle().stroke(Palette.hairline, lineWidth: 1))
            Text(color.descriptiveName.capitalizedFirst)
                .font(.sans(12, .medium))
                .foregroundColor(Palette.ink)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Palette.surface))
        .overlay(Capsule().stroke(Palette.hairline, lineWidth: 1))
    }
}
