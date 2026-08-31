import AppKit
import SwiftUI

struct SplitterView: View {
    @ObservedObject var model: SplitterViewModel
    @State private var isDropTargeted = false

    var body: some View {
        ToolWorkspace(
            title: "Image Splitter",
            subtitle: "Create perfectly ordered rows or columns without losing a pixel.",
            navigationTitle: "Splitter"
        ) {
            PreviewInspectorLayout {
                previewCard
            } inspector: {
                inspectorCard
            }
        } actionBar: {
            actionBar
        }
    }

    private var previewCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeading("Preview", number: 1)
                PreviewStage(isCanvasVisible: model.preview != nil) {
                    if let preview = model.preview {
                        GeometryReader { proxy in
                            let container = CGSize(
                                width: max(0, proxy.size.width - 20),
                                height: max(0, proxy.size.height - 20)
                            )
                            let rect = fittedRect(imageSize: preview.size, container: container)
                            Image(nsImage: preview)
                                .resizable()
                                .scaledToFit()
                                .frame(width: rect.width, height: rect.height)
                                .position(x: rect.midX, y: rect.midY)
                            sliceOverlay(in: rect)
                        }
                    } else {
                        FileDropWell(isTargeted: isDropTargeted, action: model.chooseInput) {
                            ImageDropPrompt(
                                icon: "square.split.2x1",
                                title: "Add an Image",
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
                .accessibilityLabel(model.input == nil ? "Image drop area" : "Split preview with \(model.count) slices")

                if let input = model.input {
                    SelectedImageRow(input: input, change: model.chooseInput)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var inspectorCard: some View {
        SurfaceCard {
            ScrollView {
                VStack(alignment: .leading, spacing: PFSpacing.card) {
                    SectionHeading("Split Direction", number: 2)
                    Picker("Direction", selection: $model.orientation) {
                        Label("Rows", systemImage: "rectangle.split.1x2").tag(SplitOrientation.horizontal)
                        Label("Columns", systemImage: "rectangle.split.2x1").tag(SplitOrientation.vertical)
                    }
                    .pickerStyle(.segmented)

                    Divider()
                    SectionHeading("Number of Slices", number: 3)
                    HStack(alignment: .firstTextBaseline, spacing: PFSpacing.compact) {
                        Text("\(model.count)")
                            .font(.title2.monospacedDigit().bold())
                        Text(model.count == 1 ? "slice" : "slices")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: PFSpacing.control) {
                        Button {
                            model.count = max(2, model.count - 1)
                        } label: {
                            Image(systemName: "minus")
                                .frame(width: 18, height: 18)
                        }
                        .accessibilityLabel("Decrease number of slices")
                        .disabled(model.count <= 2)

                        VStack(spacing: PFSpacing.micro) {
                            Slider(value: sliceCount, in: 2...Double(SplitterEngine.maximumSlices), step: 1) {
                                Text("Number of slices")
                            }
                            .labelsHidden()
                            .accessibilityValue("\(model.count) slices")

                            HStack {
                                Text("2")
                                Spacer()
                                Text("\(SplitterEngine.maximumSlices)")
                            }
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        }

                        Button {
                            model.count = min(SplitterEngine.maximumSlices, model.count + 1)
                        } label: {
                            Image(systemName: "plus")
                                .frame(width: 18, height: 18)
                        }
                        .accessibilityLabel("Increase number of slices")
                        .disabled(model.count >= SplitterEngine.maximumSlices)
                    }
                    Text("Each part receives an equal share. Remainder pixels are distributed without cropping.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    splitRatioSummary
                    InstagramSplitHint(parts: model.count)

                    Divider()
                    SectionHeading("Output Folder", number: 4)
                    FolderPickerRow(folder: model.outputFolder, placeholder: "Choose a folder", action: model.chooseOutput)
                    if let output = model.outputFolder {
                        Text(output.path(percentEncoded: false))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(PFSpacing.micro)
            }
            .scrollIndicators(.automatic)
        }
        .frame(width: PFLayout.inspectorWidth)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var actionBar: some View {
        ToolActionBar(
            title: actionTitle,
            detail: "Parts keep the source file format and use collision-safe names."
        ) {
            if !model.progressText.isEmpty, !model.isRunning, model.outputFolder != nil {
                Button("Reveal Output", action: model.revealOutput)
            }
            if model.isRunning {
                ProgressView().controlSize(.small)
                ToolCancelButton(action: model.cancel)
            } else {
                Button(action: model.split) {
                    Text("Split into \(model.count) Parts")
                        .frame(minWidth: PFLayout.primaryActionMinimumWidth)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(model.input == nil || model.outputFolder == nil)
                .primaryActionHover()
            }
        }
    }

    @ViewBuilder private var splitRatioSummary: some View {
        if let source = model.sourceDimensions {
            VStack(alignment: .leading, spacing: PFSpacing.compact) {
                ratioRow(label: "Source", value: source.summary)
                if !model.partDimensions.isEmpty {
                    ratioRow(label: model.orientation == .vertical ? "Each column" : "Each row", value: partRatioSummary)
                }
            }
            .padding(PFSpacing.control)
            .background(PFTheme.secondarySurface, in: RoundedRectangle(cornerRadius: PFRadius.control))
            .overlay { RoundedRectangle(cornerRadius: PFRadius.control).stroke(PFTheme.border) }
            .accessibilityElement(children: .combine)
        }
    }

    private func ratioRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: PFSpacing.micro) {
            Text(label)
                .font(.caption.weight(.semibold))
            Text(value)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private var partRatioSummary: String {
        let parts = model.partDimensions
        guard let first = parts.first else { return "Unavailable" }
        guard !parts.allSatisfy({ $0 == first }) else { return first.summary }

        let minimumWidth = parts.map(\.width).min() ?? first.width
        let maximumWidth = parts.map(\.width).max() ?? first.width
        let minimumHeight = parts.map(\.height).min() ?? first.height
        let maximumHeight = parts.map(\.height).max() ?? first.height
        let ratios = parts.map(\.ratio)
        let minimumRatio = ratios.min() ?? first.ratio
        let maximumRatio = ratios.max() ?? first.ratio
        let minimumRatioText = formattedRatio(minimumRatio)
        let maximumRatioText = formattedRatio(maximumRatio)
        let ratioRange =
            minimumRatioText == maximumRatioText
            ? "ratio ≈\(minimumRatioText)"
            : "ratio \(minimumRatioText)–\(maximumRatioText)"
        return
            "\(dimensionRange(minimumWidth, maximumWidth)) × \(dimensionRange(minimumHeight, maximumHeight)) px • \(ratioRange)"
    }

    private func dimensionRange(_ minimum: Int, _ maximum: Int) -> String {
        minimum == maximum ? String(minimum) : "\(minimum)–\(maximum)"
    }

    private var actionTitle: String {
        if !model.progressText.isEmpty { return model.progressText }
        if model.input == nil { return "Add an image to begin" }
        if model.outputFolder == nil { return "Choose an output folder" }
        return "Ready to split locally"
    }

    private func fittedRect(imageSize: CGSize, container: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return .zero }
        let scale = min(container.width / imageSize.width, container.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(
            x: (container.width - size.width) / 2 + 10,
            y: (container.height - size.height) / 2 + 10,
            width: size.width,
            height: size.height
        )
    }

    private var sliceCount: Binding<Double> {
        Binding(
            get: { Double(model.count) },
            set: { model.count = Int($0.rounded()) }
        )
    }

    private func sliceOverlay(in rect: CGRect) -> some View {
        Canvas { context, _ in
            // Guides use the fitted image rect so letterboxed preview space is never counted as a slice.
            for index in 1..<model.count {
                var path = Path()
                if model.orientation == .vertical {
                    let x = rect.minX + rect.width * CGFloat(index) / CGFloat(model.count)
                    path.move(to: CGPoint(x: x, y: rect.minY))
                    path.addLine(to: CGPoint(x: x, y: rect.maxY))
                } else {
                    let y = rect.minY + rect.height * CGFloat(index) / CGFloat(model.count)
                    path.move(to: CGPoint(x: rect.minX, y: y))
                    path.addLine(to: CGPoint(x: rect.maxX, y: y))
                }
                context.stroke(
                    path,
                    with: .color(PFTheme.coral.opacity(0.9)),
                    style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                )
            }
        }
        .allowsHitTesting(false)
    }
}
