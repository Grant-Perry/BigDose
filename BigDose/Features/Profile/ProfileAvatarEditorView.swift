import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct ProfileAvatarEditorView: View {
    @Environment(\.dismiss) private var dismiss

    var existingImageData: Data?
    var onSave: (Data?) -> Void

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var sourceImage: UIImage?
    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1
    @State private var lastOffset: CGSize = .zero
    @State private var isShowingFileImporter = false

    private let cropDiameter: CGFloat = 280

    var body: some View {
        NavigationStack {
            ZStack {
                BigDoseGradientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        cropCard
                        pickerActions

                        if sourceImage != nil {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Zoom")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white.opacity(0.56))

                                Slider(value: $scale, in: 1...3, step: 0.01)
                                    .tint(.solarGold)
                            }
                            .padding(.horizontal, 4)

                            Text("Pinch to zoom and drag to reposition your face inside the circle.")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.62))
                        }
                    }
                    .padding(18)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Profile Photo")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAvatar()
                    }
                    .disabled(sourceImage == nil)
                }
            }
            .fileImporter(isPresented: $isShowingFileImporter, allowedContentTypes: [.image]) { result in
                importImage(from: result)
            }
            .onAppear {
                if let existingImageData, let image = UIImage(data: existingImageData) {
                    sourceImage = image
                }
            }
            .onChange(of: selectedPhotoItem) { _, item in
                guard let item else { return }
                Task {
                    await loadPhoto(from: item)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Profile Photo")
                .font(.system(.largeTitle, weight: .semibold))
                .foregroundStyle(.white)

            Text("Choose a photo, then zoom and move it until it looks right in the circle.")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
        }
    }

    private var cropCard: some View {
        GlassCard {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.black.opacity(0.35))

                    if let sourceImage {
                        Image(uiImage: sourceImage)
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(scale)
                            .offset(offset)
                            .frame(width: cropDiameter, height: cropDiameter)
                            .clipped()
                            .clipShape(Circle())
                            .gesture(dragGesture.simultaneously(with: magnificationGesture))
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 54, weight: .semibold))
                                .foregroundStyle(.solarGold)

                            Text("No photo selected")
                                .font(.bigDoseHeader(.headline).weight(.semibold))
                                .foregroundStyle(.white.opacity(0.72))
                        }
                    }

                    Circle()
                        .strokeBorder(.white.opacity(0.85), lineWidth: 2)
                        .frame(width: cropDiameter, height: cropDiameter)
                        .allowsHitTesting(false)
                }
                .frame(maxWidth: .infinity)
                .frame(height: cropDiameter + 24)
            }
        }
    }

    private var pickerActions: some View {
        GlassCard {
            VStack(spacing: 12) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Choose from Photos", systemImage: "photo.on.rectangle.angled")
                        .font(.bigDoseHeader(.headline).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.solarOrange)

                Button {
                    isShowingFileImporter = true
                } label: {
                    Label("Import Image File", systemImage: "folder")
                        .font(.bigDoseHeader(.headline).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .tint(.solarGold)

                if sourceImage != nil {
                    Button(role: .destructive) {
                        resetSelection()
                    } label: {
                        Label("Remove Photo", systemImage: "trash")
                            .font(.bigDoseHeader(.headline).weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(max(lastScale * value, 1), 3)
            }
            .onEnded { _ in
                lastScale = scale
            }
    }

    private func loadPhoto(from item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            return
        }

        await MainActor.run {
            applySourceImage(image)
        }
    }

    private func importImage(from result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            guard let image = UIImage(data: data) else { return }
            applySourceImage(image)
        } catch {
            return
        }
    }

    private func applySourceImage(_ image: UIImage) {
        sourceImage = image
        scale = 1
        offset = .zero
        lastScale = 1
        lastOffset = .zero
    }

    private func resetSelection() {
        sourceImage = nil
        selectedPhotoItem = nil
        scale = 1
        offset = .zero
        lastScale = 1
        lastOffset = .zero
    }

    private func saveAvatar() {
        guard let sourceImage else {
            onSave(nil)
            dismiss()
            return
        }

        let jpegData = ProfileAvatarProcessor.jpegData(
            from: sourceImage,
            scale: scale,
            offset: offset,
            cropDiameter: cropDiameter
        )
        onSave(jpegData)
        dismiss()
    }
}
