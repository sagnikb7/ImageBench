import AppKit
import SwiftUI

struct AspectFillerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject var model: AspectFillerViewModel
    @State private var isDropTargeted = false

    var body: some View {
        ToolWorkspace(
            title: "Aspect Ratio Filler",
            subtitle: "Extend the canvas beautifully without cropping the original.",
            navigationTitle: "Aspect Filler"
        ) {
            PreviewInspectorLayout {
                previewCard
            } inspector: {
                inspectorCard
            }
        } actionBar: {
            actionBar
        }
        .onChange(of: model.preset) { model.refreshPreview() }
        .onChange(of: model.fillStyle) { model.refreshPreview() }
        .onChange(of: model.customWidth) {
            if model.preset == .custom { model.refreshPreview(debounced: true) }
        }
        .onChange(of: model.customHeight) {
            if model.preset == .custom { model.refreshPreview(debounced: true) }
        }
    }

    private var previewCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeading("Live Preview", number: 1)
                PreviewStage(isCanvasVisible: model.preview != nil) {
                    if let preview = model.preview {
                        Image(nsImage: preview)
                            .resizable()
                            .scaledToFit()
                            .padding(22)
                            .id(ObjectIdentifier(preview))
                            .transition(.opacity)
                    } else {
                        FileDropWell(isTargeted: isDropTargeted, action: model.chooseInput) {
                            ImageDropPrompt(
                                icon: "aspectratio",
                                title: "Add an Image",
                                subtitle: "Drop a JPEG, PNG, or HEIC here or click to browse"
                            )
                        }
                        .padding(PFSpacing.section)
                    }
                    if model.isRendering { ProgressView().controlSize(.large) }
                }
                .animation(reduceMotion ? nil : .easeOut(duration: 0.14), value: model.preview.map(ObjectIdentifier.init))
                .dropDestination(for: URL.self) { urls, _ in
                    model.acceptDropped(urls)
                } isTargeted: {
                    isDropTargeted = $0
                }
                .accessibilityLabel(model.input == nil ? "Image drop area" : "Live aspect ratio preview")

                if let input = model.input {
                    SelectedImageRow(input: input, change: model.chooseInput)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var inspectorCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: PFSpacing.card) {
                SectionHeading("Canvas Ratio", number: 2)
                Text(model.sourceRatioDescription)
                    .font(BrandTypography.caption)
                    .foregroundStyle(.secondary)
                SelectionField(label: "Canvas ratio", value: model.preset.label, help: model.preset.help) {
                    ForEach(AspectPreset.allCases) { preset in
                        Button {
                            model.preset = preset
                        } label: {
                            if model.preset == preset {
                                Label(preset.label, systemImage: "checkmark")
                            } else {
                                Text(preset.label)
                            }
                        }
                    }
                }
                if model.preset == .custom {
                    HStack {
                        TextField("Width", value: $model.customWidth, format: .number).frame(width: 72)
                        Text(":").foregroundStyle(.secondary)
                        TextField("Height", value: $model.customHeight, format: .number).frame(width: 72)
                    }
                }

                Divider()
                SectionHeading("Fill Style", number: 3)
                HStack(spacing: PFSpacing.compact) {
                    ForEach(FillStyle.allCases) { style in
                        SelectableCardButton(
                            isSelected: model.fillStyle == style,
                            accessibilityLabel: "\(style.rawValue) fill style",
                            accessibilityHint: description(for: style),
                            action: { model.fillStyle = style }
                        ) {
                            VStack(spacing: PFSpacing.micro) {
                                Image(systemName: icon(for: style))
                                    .font(BrandTypography.title3)
                                    .foregroundStyle(model.fillStyle == style ? PFTheme.coral : .secondary)
                                    .accessibilityHidden(true)
                                Text(style.rawValue)
                                    .font(BrandTypography.caption.weight(.medium))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                }
                Text(fillDescription)
                    .font(BrandTypography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: PFLayout.inspectorWidth)
    }

    private var actionBar: some View {
        ToolActionBar(
            title: actionTitle,
            detail: "The original stays centered, uncropped, and untouched."
        ) {
            if model.isExporting {
                ProgressView().controlSize(.small)
                ToolCancelButton(action: model.cancelExport)
            } else {
                Button(action: model.export) {
                    Text("Export")
                        .frame(minWidth: PFLayout.primaryActionMinimumWidth)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(model.input == nil || model.isRendering)
                .accessibilityLabel("Export filled image")
                .accessibilityHint("Opens a save dialog")
                .primaryActionHover()
            }
        }
    }

    private var actionTitle: String {
        if !model.message.isEmpty { return model.message }
        if model.input == nil { return "Add an image to begin" }
        if model.isRendering { return "Updating preview…" }
        return "Ready to export locally"
    }

    private var fillDescription: String {
        description(for: model.fillStyle)
    }

    private func description(for style: FillStyle) -> String {
        switch style {
        case .white: "Adds a clean white canvas around the original."
        case .black: "Adds a deep black canvas around the original."
        case .blur: "Fills the canvas with a softly blurred version of the photo."
        }
    }

    private func icon(for style: FillStyle) -> String {
        switch style {
        case .white: "sun.max.fill"
        case .black: "moon.fill"
        case .blur: "aqi.medium"
        }
    }
}
