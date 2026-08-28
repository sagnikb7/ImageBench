import AppKit
import SwiftUI

struct ExifViewerView: View {
    @ObservedObject var model: ExifViewerViewModel
    @State private var isDropTargeted = false
    @State private var metadataSearch = ""

    var body: some View {
        ToolWorkspace(
            title: "EXIF Viewer",
            subtitle: "Inspect camera metadata and tonal distribution without uploading a file.",
            navigationTitle: "EXIF Viewer"
        ) {
            ScrollView {
                HStack(alignment: .top, spacing: PFSpacing.section) {
                    VStack(spacing: PFSpacing.section) {
                        previewCard
                        histogramCard
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                    metadataCard
                        .frame(width: 400)
                }
                .padding(.horizontal, PFSpacing.screen)
                .padding(.top, PFSpacing.card)
                .padding(.bottom, PFSpacing.card)
            }
        } actionBar: {
            actionBar
        }
    }

    private var previewCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: PFSpacing.control) {
                SectionHeading("Preview", number: 1)
                ZStack {
                    if let preview = model.inspection?.preview {
                        Image(nsImage: preview)
                            .resizable()
                            .scaledToFit()
                            .padding(PFSpacing.section)
                    } else {
                        FileDropWell(isTargeted: isDropTargeted, action: model.chooseInput) {
                            ImageDropPrompt(
                                icon: "camera.metering.matrix",
                                title: model.isLoading ? "Reading Image" : "Add an Image or RAW File",
                                subtitle: "JPEG, HEIC, TIFF, DNG, CR2/CR3, NEF, ARW, RAF, ORF, RW2, and PEF"
                            )
                        }
                        .disabled(model.isLoading)
                        .padding(PFSpacing.section)
                    }
                    if model.isLoading {
                        ProgressView()
                            .controlSize(.large)
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: PFRadius.control))
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 350)
                .background {
                    if model.inspection?.preview != nil {
                        RoundedRectangle(cornerRadius: PFRadius.inset, style: .continuous)
                            .fill(PFTheme.mediaStageSurface)
                    }
                }
                .overlay {
                    if model.inspection?.preview != nil {
                        RoundedRectangle(cornerRadius: PFRadius.inset, style: .continuous)
                            .stroke(PFTheme.border)
                    }
                }
                .dropDestination(for: URL.self) { urls, _ in
                    model.acceptDropped(urls)
                } isTargeted: {
                    isDropTargeted = $0
                }
                .accessibilityLabel(model.inspection?.preview == nil ? "Image and RAW drop area" : "Image preview")

                if let input = model.input {
                    SelectedImageRow(input: input, change: model.chooseInput)
                }
            }
        }
    }

    private var histogramCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: PFSpacing.control) {
                HStack {
                    SectionHeading("Histogram")
                    Spacer()
                    Text("Log scale")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                HistogramPlot(histogram: model.inspection?.histogram ?? .empty)
                    .frame(height: 150)
                HStack(spacing: PFSpacing.control) {
                    HistogramLegend(label: "Luminance", color: .primary)
                    HistogramLegend(label: "Red", color: .red)
                    HistogramLegend(label: "Green", color: .green)
                    HistogramLegend(label: "Blue", color: .blue)
                }
                .font(.caption2)
            }
        }
    }

    private var metadataCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: PFSpacing.control) {
                SectionHeading("Metadata", number: 2)
                TextField("Filter metadata", text: $metadataSearch)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Filter metadata")

                if filteredSections.isEmpty {
                    VStack(spacing: PFSpacing.compact) {
                        Image(systemName: model.inspection == nil ? "doc.text.magnifyingglass" : "line.3.horizontal.decrease.circle")
                            .font(.system(size: 32))
                            .foregroundStyle(PFTheme.coral)
                            .accessibilityHidden(true)
                        Text(model.inspection == nil ? "Metadata will appear here" : "No metadata matches this filter")
                            .font(.headline)
                        Text(
                            model.inspection == nil
                                ? "ImageBench groups capture, camera, exposure, location, and RAW details locally."
                                : "Try a camera model, exposure value, or field name."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 240)
                } else {
                    LazyVStack(alignment: .leading, spacing: PFSpacing.card) {
                        ForEach(filteredSections) { section in
                            MetadataSectionView(section: section)
                            if section.id != filteredSections.last?.id { Divider() }
                        }
                    }
                }
            }
        }
    }

    private var filteredSections: [ExifMetadataSection] {
        let query = metadataSearch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return model.inspection?.sections ?? [] }
        return (model.inspection?.sections ?? []).compactMap { section in
            let fields = section.fields.filter {
                section.title.localizedCaseInsensitiveContains(query)
                    || $0.label.localizedCaseInsensitiveContains(query)
                    || $0.value.localizedCaseInsensitiveContains(query)
            }
            return fields.isEmpty ? nil : ExifMetadataSection(title: section.title, fields: fields)
        }
    }

    private var actionBar: some View {
        ToolActionBar(
            title: actionTitle,
            detail: model.input?.lastPathComponent ?? "Read-only inspection stays entirely on this Mac."
        ) {
            if model.input != nil {
                Button("Reveal in Finder", action: model.revealInput)
            }
            Button("Choose Image…", action: model.chooseInput)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(model.isLoading)
                .primaryActionHover()
        }
    }

    private var actionTitle: String {
        if !model.message.isEmpty { return model.message }
        return "Choose an image or RAW file to inspect"
    }
}

private struct MetadataSectionView: View {
    let section: ExifMetadataSection

    var body: some View {
        VStack(alignment: .leading, spacing: PFSpacing.compact) {
            Text(section.title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            ForEach(section.fields) { field in
                LabeledContent {
                    Text(field.value)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .textSelection(.enabled)
                } label: {
                    Text(field.label)
                }
                .font(.caption)
            }
        }
    }
}

private struct HistogramPlot: View {
    let histogram: ExifHistogram

    var body: some View {
        Canvas { context, size in
            for division in 1..<4 {
                let y = size.height * CGFloat(division) / 4
                var grid = Path()
                grid.move(to: CGPoint(x: 0, y: y))
                grid.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(grid, with: .color(.secondary.opacity(0.16)), lineWidth: 0.5)
            }
            draw(histogram.luminance, color: .primary.opacity(0.72), context: &context, size: size, width: 1.4)
            draw(histogram.red, color: .red.opacity(0.72), context: &context, size: size)
            draw(histogram.green, color: .green.opacity(0.72), context: &context, size: size)
            draw(histogram.blue, color: .blue.opacity(0.72), context: &context, size: size)
        }
        .background(PFTheme.secondarySurface, in: RoundedRectangle(cornerRadius: PFRadius.control))
        .overlay { RoundedRectangle(cornerRadius: PFRadius.control).stroke(PFTheme.border) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("RGB and luminance histogram")
    }

    private func draw(
        _ values: [Double],
        color: Color,
        context: inout GraphicsContext,
        size: CGSize,
        width: CGFloat = 1
    ) {
        guard values.count > 1 else { return }
        var path = Path()
        for (index, value) in values.enumerated() {
            let point = CGPoint(
                x: size.width * CGFloat(index) / CGFloat(values.count - 1),
                y: size.height * CGFloat(1 - value)
            )
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        context.stroke(path, with: .color(color), lineWidth: width)
    }
}

private struct HistogramLegend: View {
    let label: String
    let color: Color

    var body: some View {
        Label {
            Text(label)
        } icon: {
            Circle().fill(color).frame(width: 7, height: 7)
        }
    }
}
