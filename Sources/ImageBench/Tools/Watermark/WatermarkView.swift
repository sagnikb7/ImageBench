import AppKit
import SwiftUI

struct WatermarkView: View {
    @ObservedObject var model: WatermarkViewModel
    @State private var isDropTargeted = false
    @State private var confirmsSelectedReset = false
    @State private var confirmsAllReset = false

    var body: some View {
        ToolWorkspace(
            title: "Watermark Studio",
            subtitle: "Add a reusable signature without opening a heavyweight editor.",
            navigationTitle: "Watermark"
        ) {
            PreviewInspectorLayout {
                previewCard
            } inspector: {
                inspectorCard
            }
        } actionBar: {
            actionBar
        }
        .task {
            model.preparePreview()
            await model.loadPresets()
        }
        .onChange(of: model.draft.text) { model.updateText() }
        .onChange(of: model.textColor) { model.updateText() }
        .confirmationDialog(
            "Reset Preset \(model.selectedSlot)?",
            isPresented: $confirmsSelectedReset,
            titleVisibility: .visible
        ) {
            Button("Reset Preset \(model.selectedSlot)", role: .destructive) {
                Task { await model.resetSelectedPreset() }
            }
        } message: {
            Text("This removes the saved watermark and its app-managed image, if any.")
        }
        .confirmationDialog("Reset All Presets?", isPresented: $confirmsAllReset, titleVisibility: .visible) {
            Button("Reset All Presets", role: .destructive) {
                Task { await model.resetAllPresets() }
            }
        } message: {
            Text("This removes all four saved watermark presets and their app-managed images.")
        }
    }

    private var previewCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeading("Live Preview", number: 1)
                PreviewStage(isCanvasVisible: model.sourcePreview != nil) {
                    if let source = model.sourcePreview {
                        WatermarkCanvas(
                            source: source,
                            watermark: model.watermarkPreview,
                            draft: model.draft,
                            onMove: model.updatePlacement
                        )
                        .padding(22)
                    } else {
                        FileDropWell(isTargeted: isDropTargeted, action: model.chooseInput) {
                            ImageDropPrompt(
                                icon: "signature",
                                title: "Add a Photo",
                                subtitle: "Drop a JPEG, PNG, or HEIC here or click to browse"
                            )
                        }
                        .padding(PFSpacing.section)
                    }
                }
                .dropDestination(for: URL.self) { urls, _ in
                    model.acceptDropped(urls)
                } isTargeted: {
                    isDropTargeted = $0
                }
                .accessibilityLabel(model.input == nil ? "Photo drop area" : "Watermark preview")

                if let input = model.input {
                    SelectedImageRow(input: input, change: model.chooseInput)
                    Label("Drag the watermark on the preview to place it.", systemImage: "arrow.up.and.down.and.arrow.left.and.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var inspectorCard: some View {
        SurfaceCard {
            ScrollView {
                VStack(alignment: .leading, spacing: PFSpacing.card) {
                    presetSection
                    Divider()
                    contentSection
                    Divider()
                    placementSection
                }
            }
            .scrollIndicators(.automatic)
        }
        .frame(width: PFLayout.inspectorWidth)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: PFSpacing.control) {
            SectionHeading("Preset Slot", number: 2)
            HStack(spacing: PFSpacing.compact) {
                ForEach(1...4, id: \.self) { slot in
                    PresetSlotButton(
                        slot: slot,
                        isSelected: model.selectedSlot == slot,
                        isSaved: model.presets[slot] != nil,
                        action: { model.selectPreset(slot: slot) }
                    )
                }
            }
            Text("Export saves the current watermark, size, and position to the selected slot.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: PFSpacing.compact) {
                Button("Reset Selected…", role: .destructive) { confirmsSelectedReset = true }
                    .disabled(model.presets[model.selectedSlot] == nil)
                Button("Reset All…", role: .destructive) { confirmsAllReset = true }
                    .disabled(model.presets.isEmpty)
            }
            .font(.caption)
        }
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: PFSpacing.control) {
            SectionHeading("Watermark", number: 3)
            Picker(
                "Type",
                selection: Binding(
                    get: { model.draft.kind },
                    set: { model.selectKind($0) }
                )
            ) {
                ForEach(WatermarkKind.allCases) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            if model.draft.kind == .text {
                TextField("Signature or copyright", text: $model.draft.text)
                    .textFieldStyle(.roundedBorder)
                    .font(.custom(WatermarkEngine.textFontName, size: NSFont.systemFontSize))
                ColorPicker("Text Color", selection: $model.textColor, supportsOpacity: false)
            } else if let watermarkImageURL = model.watermarkImageURL {
                SelectedImageRow(input: watermarkImageURL, change: model.chooseWatermarkImage)
                Text("ImageBench keeps an app-managed copy when this preset is saved.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Button("Choose Watermark Image…", action: model.chooseWatermarkImage)
            }
        }
    }

    private var placementSection: some View {
        VStack(alignment: .leading, spacing: PFSpacing.control) {
            SectionHeading("Size & Placement", number: 4)
            LabeledContent("Size", value: "\(Int((model.draft.relativeWidth * 100).rounded()))%")
            Slider(value: $model.draft.relativeWidth, in: 0.05...0.8)
                .accessibilityLabel("Watermark size")
            LabeledContent("Opacity", value: "\(Int((model.draft.opacity * 100).rounded()))%")
            Slider(value: $model.draft.opacity, in: 0.1...1)
                .accessibilityLabel("Watermark opacity")
            HStack {
                Text("Drag directly on the photo.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Center", action: model.centerWatermark)
            }
        }
    }

    private var actionBar: some View {
        ToolActionBar(
            title: actionTitle,
            detail: "The original stays untouched; export also updates the selected preset."
        ) {
            if let _ = model.lastOutput, !model.isExporting {
                Button("Reveal Output", action: model.revealOutput)
            }
            if model.isExporting {
                ProgressView().controlSize(.small)
                ToolCancelButton(action: model.cancel)
            } else {
                Button(action: model.export) {
                    Text("Export")
                        .frame(minWidth: PFLayout.primaryActionMinimumWidth)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!model.canExport)
                .accessibilityLabel("Export watermarked copy")
                .accessibilityHint("Opens a save dialog")
                .primaryActionHover()
            }
        }
    }

    private var actionTitle: String {
        if !model.message.isEmpty { return model.message }
        if model.input == nil { return "Add a photo to begin" }
        if !model.canExport {
            return model.draft.kind == .text ? "Enter watermark text" : "Choose a watermark image"
        }
        return "Ready to watermark locally"
    }
}

private struct PresetSlotButton: View {
    let slot: Int
    let isSelected: Bool
    let isSaved: Bool
    let action: () -> Void

    var body: some View {
        SelectableCardButton(
            isSelected: isSelected,
            accessibilityLabel: "Preset \(slot), \(isSaved ? "saved" : "empty")",
            accessibilityHint: isSaved
                ? "Loads this saved watermark preset."
                : "Selects this slot for the next successful export.",
            action: action
        ) {
            VStack(spacing: 3) {
                Text("\(slot)").font(.headline.monospacedDigit())
                Text(isSaved ? "Saved" : "Empty")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct WatermarkCanvas: View {
    let source: NSImage
    let watermark: NSImage?
    let draft: WatermarkDraft
    let onMove: (Double, Double) -> Void

    var body: some View {
        GeometryReader { proxy in
            let sourceRect = fittedRect(imageSize: source.size, container: proxy.size)
            ZStack(alignment: .topLeading) {
                Image(nsImage: source)
                    .resizable()
                    .scaledToFit()
                    .frame(width: sourceRect.width, height: sourceRect.height)
                    .position(x: sourceRect.midX, y: sourceRect.midY)

                if let watermark, watermark.size.width > 0, watermark.size.height > 0 {
                    let localFrame = WatermarkLayout.frame(
                        canvasSize: sourceRect.size,
                        overlayAspectRatio: watermark.size.width / watermark.size.height,
                        draft: draft
                    )
                    let frame = localFrame.offsetBy(dx: sourceRect.minX, dy: sourceRect.minY)
                    Image(nsImage: watermark)
                        .resizable()
                        .scaledToFit()
                        .opacity(draft.normalized().opacity)
                        .frame(width: frame.width, height: frame.height)
                        .overlay {
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(
                                    PFTheme.coral,
                                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [5, 3])
                                )
                                .shadow(color: .black.opacity(0.65), radius: 1)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                        .position(x: frame.midX, y: frame.midY)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .named("watermarkCanvas"))
                                .onChanged { value in
                                    onMove(
                                        Double((value.location.x - sourceRect.minX) / sourceRect.width),
                                        Double((value.location.y - sourceRect.minY) / sourceRect.height)
                                    )
                                }
                        )
                        .accessibilityLabel("Watermark")
                        .accessibilityHint("Drag to reposition the watermark on the photo")
                }
            }
            .coordinateSpace(name: "watermarkCanvas")
        }
    }

    private func fittedRect(imageSize: CGSize, container: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return .zero }
        let scale = min(container.width / imageSize.width, container.height / imageSize.height)
        let fitted = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(
            x: (container.width - fitted.width) / 2,
            y: (container.height - fitted.height) / 2,
            width: fitted.width,
            height: fitted.height
        )
    }
}
