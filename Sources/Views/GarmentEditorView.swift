import SwiftUI
import PhotosUI
import UIKit

struct GarmentEditorView: View {
    @EnvironmentObject private var store: WardrobeStore

    @State private var garment: Garment
    @State private var pickedImage: UIImage?
    @State private var removeImage = false
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var cameraUnavailable = false

    init(garment: Garment) {
        _garment = State(initialValue: garment)
    }

    private var isExisting: Bool {
        store.garments.contains { $0.id == garment.id }
    }

    private var previewImage: UIImage? {
        if removeImage { return nil }
        if let pickedImage { return pickedImage }
        return store.image(for: garment)
    }

    private var canSave: Bool {
        !garment.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ModalScaffold(title: isExisting ? "Modifica capo" : "Nuovo capo",
                      kicker: "Armadio",
                      trailing: AnyView(saveButton)) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    photoSection
                    detailsSection
                    colorSection
                    attributesSection
                    notesSection
                }
                .padding(22)
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                pickedImage = image
                removeImage = false
                showCamera = false
                if let suggested = DominantColor.suggestColor(from: image) {
                    garment.colorHex = suggested.hex
                }
            }
            .ignoresSafeArea()
        }
        .alert("Fotocamera non disponibile", isPresented: $cameraUnavailable) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Su questo dispositivo non risulta una fotocamera utilizzabile: puoi aggiungere la foto dalla libreria.")
        }
        .onChange(of: photoItem) { item in
            guard let item else { return }
            Task {
                let data = try? await item.loadTransferable(type: Data.self)
                await MainActor.run {
                    if let data, let image = UIImage(data: data) {
                        pickedImage = image
                        removeImage = false
                        if let suggested = DominantColor.suggestColor(from: image) {
                            garment.colorHex = suggested.hex
                        }
                    }
                    photoItem = nil
                }
            }
        }
    }

    private var saveButton: some View {
        Button {
            save()
        } label: {
            Text("Salva")
        }
        .buttonStyle(CTAButtonStyle())
        .disabled(!canSave)
        .opacity(canSave ? 1 : 0.45)
    }

    // MARK: Foto

    private var photoSection: some View {
        HStack(alignment: .top, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Palette.ivory)
                if let image = previewImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    VStack(spacing: 7) {
                        Image(systemName: "camera")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(Palette.inkSoft)
                        Text("Nessuna foto")
                            .font(.sans(11))
                            .foregroundColor(Palette.inkSoft)
                    }
                }
            }
            .frame(width: 170, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Palette.hairline, lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("Foto del capo")
                    .font(.serif(20, .semibold))
                    .foregroundColor(Palette.ink)
                Text("Scatta una foto al volo o prendila dalla libreria dell'iPad. Il colore viene rilevato automaticamente e puoi sempre correggerlo.")
                    .font(.sans(12))
                    .foregroundColor(Palette.inkSoft)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 9) {
                    Button {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            showCamera = true
                        } else {
                            cameraUnavailable = true
                        }
                    } label: {
                        Label("Fotocamera", systemImage: "camera")
                    }
                    .buttonStyle(CTAButtonStyle())

                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("Libreria", systemImage: "photo.on.rectangle")
                            .font(.sans(14, .semibold))
                            .foregroundColor(Palette.ink)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 11)
                            .background(
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .fill(Palette.ivory)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .stroke(Palette.hairline, lineWidth: 1)
                            )
                    }
                }

                if previewImage != nil {
                    Button {
                        pickedImage = nil
                        removeImage = true
                    } label: {
                        Text("Rimuovi foto")
                            .font(.sans(12, .medium))
                            .foregroundColor(Palette.warning)
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer(minLength: 0)
        }
        .card()
    }

    // MARK: Dettagli

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Dettagli")
                .font(.serif(20, .semibold))
                .foregroundColor(Palette.ink)

            labeledField("Nome del capo", text: $garment.name, placeholder: "Es. Camicia di lino")
            labeledField("Marca", text: $garment.brand, placeholder: "Facoltativa")

            VStack(alignment: .leading, spacing: 7) {
                FieldLabel(text: "Categoria")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)],
                          alignment: .leading,
                          spacing: 8) {
                    ForEach(GarmentCategory.allCases) { category in
                        Chip(title: category.shortTitle, isSelected: garment.category == category) {
                            garment.category = category
                        }
                    }
                }
            }
        }
        .card()
    }

    private func labeledField(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            FieldLabel(text: label)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.sans(14))
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Palette.ivory))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Palette.hairline, lineWidth: 1)
                )
        }
    }

    // MARK: Colore

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text("Colore")
                    .font(.serif(20, .semibold))
                    .foregroundColor(Palette.ink)
                Spacer()
                Text(garment.rgb.descriptiveName.capitalizedFirst)
                    .font(.sans(11, .semibold))
                    .foregroundColor(Palette.brass)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 38), spacing: 9)],
                      alignment: .leading,
                      spacing: 9) {
                ForEach(ColorFamily.allCases) { family in
                    Button {
                        garment.colorHex = family.referenceRGB.hex
                    } label: {
                        Circle()
                            .fill(family.referenceRGB.color)
                            .frame(width: 32, height: 32)
                            .overlay(Circle().stroke(Palette.hairline, lineWidth: 1))
                            .overlay(
                                Circle()
                                    .stroke(Palette.ink, lineWidth: 2)
                                    .padding(-4)
                                    .opacity(ColorFamily.family(for: garment.rgb) == family ? 1 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 12) {
                ColorPicker("Sfumatura esatta",
                            selection: Binding(get: { garment.rgb.color },
                                               set: { garment.colorHex = $0.hexString }),
                            supportsOpacity: false)
                    .font(.sans(13))
                Spacer(minLength: 0)
            }

            if let image = previewImage {
                Button {
                    if let suggested = DominantColor.suggestColor(from: image) {
                        garment.colorHex = suggested.hex
                    }
                } label: {
                    Label("Rileva dalla foto", systemImage: "eyedropper")
                }
                .buttonStyle(CTAButtonStyle(filled: false))
            }
        }
        .card()
    }

    // MARK: Attributi

    private var attributesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Caratteristiche")
                .font(.serif(20, .semibold))
                .foregroundColor(Palette.ink)

            VStack(alignment: .leading, spacing: 7) {
                FieldLabel(text: "Fantasia")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)],
                          alignment: .leading,
                          spacing: 8) {
                    ForEach(Pattern.allCases) { pattern in
                        Chip(title: pattern.title, isSelected: garment.pattern == pattern) {
                            garment.pattern = pattern
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 7) {
                FieldLabel(text: "Occasione")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)],
                          alignment: .leading,
                          spacing: 8) {
                    ForEach(Formality.allCases) { formality in
                        Chip(title: formality.title, isSelected: garment.formality == formality) {
                            garment.formality = formality
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 7) {
                FieldLabel(text: "Stagioni")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)],
                          alignment: .leading,
                          spacing: 8) {
                    ForEach(Season.allCases) { season in
                        Chip(title: season.title, isSelected: garment.seasons.contains(season)) {
                            if garment.seasons.contains(season) {
                                if garment.seasons.count > 1 {
                                    garment.seasons.remove(season)
                                }
                            } else {
                                garment.seasons.insert(season)
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    FieldLabel(text: "Calore")
                    Spacer()
                    Text(garment.warmthText)
                        .font(.sans(11, .semibold))
                        .foregroundColor(Palette.inkSoft)
                }
                Slider(value: Binding(get: { Double(garment.warmth) },
                                      set: { garment.warmth = Int($0.rounded()) }),
                       in: 1...5,
                       step: 1)
                    .tint(Palette.brass)
            }
        }
        .card()
    }

    // MARK: Note

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            FieldLabel(text: "Note")
            TextEditor(text: $garment.notes)
                .font(.sans(14))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 88)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Palette.ivory))
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(Palette.hairline, lineWidth: 1)
                )
        }
        .card()
    }

    // MARK: Azioni

    private func save() {
        var updated = garment
        updated.name = updated.name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.brand = updated.brand.trimmingCharacters(in: .whitespacesAndNewlines)
        store.upsert(updated, image: pickedImage, removeImage: removeImage)
        dismiss()
    }

    @Environment(\.dismiss) private var dismiss
}
