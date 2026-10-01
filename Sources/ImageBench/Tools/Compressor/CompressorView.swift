import SwiftUI

struct CompressorView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var dependencies: DependencyManager
    @ObservedObject var model: CompressorViewModel
    @State private var isDropTargeted = false
    @State private var showsLog = false
    @State private var showsFailures = false

    var body: some View {
        ToolWorkspace(
            title: "Bulk Compressor",
            subtitle: "Compress whole photo libraries while keeping every original untouched.",
            navigationTitle: "Compressor"
        ) {
            ScrollView {
                VStack(spacing: PFSpacing.section) {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: PFSpacing.section, alignment: .top),
                            GridItem(.flexible(), alignment: .top),
                        ], alignment: .leading, spacing: PFSpacing.section
                    ) {
                        SurfaceCard { sourceSection }
                        configurationCard
                    }
                    if let result = model.batchResult { resultCard(result) }
                    commandLog
                }
                .padding(.horizontal, PFSpacing.screen)
                .padding(.top, PFSpacing.card)
                .padding(.bottom, PFSpacing.card)
            }
        } actionBar: {
            actionBar
        }
    }

    private var sourceSection: some View {
        WorkspaceSection {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeading("Add Photos", number: 1)
                FileDropWell(isTargeted: isDropTargeted, action: model.chooseInput) {
                    VStack(spacing: 9) {
                        Image(systemName: model.images.isEmpty ? "photo.badge.plus" : "photo.stack.fill")
                            .font(.system(size: 34, weight: .medium))
                            .foregroundStyle(PFTheme.coral)
                        Text(model.images.isEmpty ? "Add Photos" : model.selectionSummary)
                            .font(BrandTypography.headline)
                        Text(
                            model.images.isEmpty
                                ? "Drop photos or a folder here" : model.inputFolder?.path(percentEncoded: false) ?? "Selected files"
                        )
                        .font(BrandTypography.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    }
                    .padding()
                }
                .dropDestination(for: URL.self) { urls, _ in
                    model.acceptDropped(urls)
                } isTargeted: {
                    isDropTargeted = $0
                }
                .accessibilityLabel("Photo and folder drop area")
                .accessibilityHint("Drop supported images or activate to choose a folder")

                if !model.images.isEmpty {
                    HStack(spacing: PFSpacing.control) {
                        Label(model.selectionSummary, systemImage: "folder.fill")
                            .font(BrandTypography.subheadline.weight(.medium))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .layoutPriority(1)
                        Spacer(minLength: PFSpacing.compact)
                        Button("Change…", action: model.chooseInput)
                            .fixedSize()
                    }
                    thumbnailStrip
                } else {
                    Text("JPEG, PNG, HEIC, HEIF, TIFF, BMP, GIF, and WebP")
                        .font(BrandTypography.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    private var thumbnailStrip: some View {
        ViewThatFits(in: .horizontal) {
            thumbnailStrip(maximumVisible: 7)
            thumbnailStrip(maximumVisible: 6)
            thumbnailStrip(maximumVisible: 5)
            thumbnailStrip(maximumVisible: 4)
            thumbnailStrip(maximumVisible: 3)
            thumbnailStrip(maximumVisible: 2)
            thumbnailStrip(maximumVisible: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Preview of selected photos")
    }

    private func thumbnailStrip(maximumVisible: Int) -> some View {
        let visibleCount = min(maximumVisible, model.images.count)
        let hiddenCount = model.images.count - visibleCount

        return HStack(spacing: 7) {
            ForEach(Array(model.images.prefix(visibleCount)), id: \.self) { url in
                AsyncThumbnailView(url: url, maxPixelSize: 160)
                    .frame(width: 58, height: 50)
                    .background(PFTheme.secondarySurface)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            }
            if hiddenCount > 0 {
                Text("+\(hiddenCount.formatted())")
                    .font(BrandTypography.caption.weight(.semibold))
                    .frame(width: 58, height: 50)
                    .background(PFTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            }
        }
    }

    private var compressionSection: some View {
        WorkspaceSection {
            VStack(alignment: .leading, spacing: PFSpacing.control) {
                SectionHeading("Compression Preset", number: 3)
                SelectionField(label: "Compression preset", value: model.preset.displayName, help: model.preset.detail) {
                    ForEach(CompressionPreset.allCases) { preset in
                        Button {
                            model.selectPreset(preset)
                        } label: {
                            if model.preset == preset {
                                Label(preset.displayName, systemImage: "checkmark")
                            } else {
                                Text(preset.displayName)
                            }
                        }
                    }
                }
                if model.preset == .custom { customControls }
            }
        }
    }

    private var metadataSection: some View {
        WorkspaceSection {
            VStack(alignment: .leading, spacing: PFSpacing.control) {
                SectionHeading("Metadata", number: 4)
                SelectionField(label: "Metadata policy", value: model.metadataPolicy.rawValue, help: model.metadataPolicy.detail) {
                    ForEach(MetadataPolicy.allCases) { policy in
                        Button {
                            model.metadataPolicy = policy
                        } label: {
                            if model.metadataPolicy == policy {
                                Label(policy.rawValue, systemImage: "checkmark")
                            } else {
                                Text(policy.rawValue)
                            }
                        }
                    }
                }
            }
        }
    }

    private var configurationCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 0) {
                WorkspaceSection {
                    VStack(alignment: .leading, spacing: PFSpacing.control) {
                        SectionHeading("Output Destination", number: 2)
                        FolderPickerRow(folder: model.outputFolder, placeholder: "Choose a destination", action: model.chooseOutput)
                    }
                }
                Divider()
                compressionSection
                Divider()
                metadataSection
                Divider()
                WorkspaceSection { dependencyStatus }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var customControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Quality \(model.options.quality)").frame(width: 90, alignment: .leading)
                Slider(
                    value: Binding(get: { Double(model.options.quality) }, set: model.setCustomQuality),
                    in: Double(CompressionOptions.customQualityRange.lowerBound)...Double(CompressionOptions.customQualityRange.upperBound),
                    step: Double(CompressionOptions.customQualityStep)
                ) {
                    Text("JPEG quality")
                }
                .accessibilityValue("\(model.options.quality) out of 100")
            }
            HStack {
                Text("0")
                Spacer()
                Text("5-point steps")
                Spacer()
                Text("100")
            }
            .font(BrandTypography.caption2.monospacedDigit())
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
            Toggle("Progressive JPEG", isOn: $model.options.progressive)
            Toggle("Optimize Huffman tables", isOn: $model.options.optimize)
            quantizationTablePicker
            Picker("Chroma sampling", selection: $model.options.sampling) {
                Text("Default").tag(""); Text("4:4:4").tag("1x1"); Text("4:2:0").tag("2x2")
            }.pickerStyle(.segmented)
        }
        .font(BrandTypography.caption)
        .padding(10)
        .background(PFTheme.secondarySurface.opacity(0.5), in: RoundedRectangle(cornerRadius: PFRadius.control))
    }

    private var quantizationTablePicker: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PFSpacing.compact) {
                Text("Quantization table")
                quantizationTableSegments
            }
            .fixedSize(horizontal: true, vertical: false)
            VStack(alignment: .leading, spacing: PFSpacing.compact) {
                Text("Quantization table")
                quantizationTableSegments
            }
        }
    }

    private var quantizationTableSegments: some View {
        Picker("Quantization table", selection: $model.options.quantTable) {
            Text("Default").tag(0)
            ForEach(1...8, id: \.self) { table in
                Text("\(table)").tag(table)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .accessibilityLabel("Quantization table")
    }

    private var dependencyStatus: some View {
        HStack(spacing: 10) {
            Image(systemName: dependencies.isReady ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(dependencies.isReady ? PFTheme.success : PFTheme.warning)
            VStack(alignment: .leading, spacing: 2) {
                Text(dependencies.isReady ? "Ready to compress offline" : "Dependencies need attention")
                    .font(BrandTypography.subheadline.weight(.semibold))
                Text(dependencies.message).font(BrandTypography.caption).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer()
            if !dependencies.isReady {
                Button(dependencies.isInstalling ? "Installing…" : "Install") { Task { await dependencies.install() } }
                    .disabled(dependencies.isInstalling)
            }
        }
    }

    private func resultCard(_ result: CompressionBatchResult) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: PFSpacing.control) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: PFSpacing.screen) {
                        resultMetrics(result)
                        Spacer(minLength: PFSpacing.section)
                        compressionSizeSummary
                    }
                    VStack(alignment: .leading, spacing: PFSpacing.control) {
                        resultMetrics(result)
                        compressionSizeSummary
                    }
                }
                HStack(spacing: PFSpacing.compact) {
                    Spacer()
                    if !result.failures.isEmpty {
                        Button("Retry Failed") { model.retryFailures(cjpeg: dependencies.cjpegURL, exiftool: dependencies.exiftoolURL) }
                        Button(showsFailures ? "Hide Issues" : "Show Issues") { showsFailures.toggle() }
                    }
                    Button("Reveal Output", action: model.revealOutput)
                }
                if showsFailures, !result.failures.isEmpty {
                    Divider()
                    ForEach(result.failures) { failure in
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill").foregroundStyle(PFTheme.danger)
                            Text(failure.input.lastPathComponent).fontWeight(.medium)
                            Text(failure.message).foregroundStyle(.secondary).lineLimit(1)
                            Spacer()
                        }
                        .font(BrandTypography.caption)
                    }
                    Button("Reveal Failed Files", action: model.revealFailures)
                        .font(BrandTypography.caption)
                }
            }
        }
    }

    private func resultMetrics(_ result: CompressionBatchResult) -> some View {
        HStack(spacing: PFSpacing.screen) {
            ResultMetric(icon: "checkmark.circle.fill", value: result.written, label: "Succeeded", color: PFTheme.success)
            ResultMetric(
                icon: "exclamationmark.triangle.fill", value: result.failures.count, label: "Need Attention", color: PFTheme.warning
            )
            ResultMetric(icon: "minus.circle.fill", value: result.skipped.count, label: "Skipped", color: .secondary)
        }
    }

    private var compressionSizeSummary: some View {
        CompressionSizeSummary(
            beforeBytes: model.inputBytesForLastRun,
            afterBytes: model.outputBytesForLastRun,
            changeBytes: model.sizeChangeBytes,
            changePercentage: model.sizeChangePercentage
        )
    }

    private var commandLog: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(reduceMotion ? nil : PFMotion.quick) {
                    showsLog.toggle()
                }
            } label: {
                HStack(spacing: PFSpacing.compact) {
                    Image(systemName: showsLog ? "chevron.down" : "chevron.right")
                        .font(BrandTypography.caption.weight(.semibold))
                        .frame(width: 12)
                        .accessibilityHidden(true)
                    Label("Command Details", systemImage: "terminal")
                        .font(BrandTypography.subheadline.weight(.medium))
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            .accessibilityLabel("Command Details")
            .accessibilityValue(showsLog ? "Expanded" : "Collapsed")
            .accessibilityHint(showsLog ? "Collapse exact commands and tool output" : "Show exact commands and tool output")

            if showsLog {
                Text(model.log.isEmpty ? "Exact commands and tool output will appear here." : model.log)
                    .textSelection(.enabled)
                    .font(BrandTypography.caption)
                    .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
                    .padding(12)
                    .background(Color.black.opacity(0.06), in: RoundedRectangle(cornerRadius: PFRadius.control))
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
            }
        }
        .background(PFTheme.surface, in: RoundedRectangle(cornerRadius: PFRadius.inset))
        .overlay { RoundedRectangle(cornerRadius: PFRadius.inset).stroke(PFTheme.border) }
        .onChange(of: showsLog, initial: true) { model.setLogVisible(showsLog) }
    }

    private var actionBar: some View {
        VStack(spacing: PFSpacing.compact) {
            if model.isRunning {
                ProgressView(value: model.progress)
                    .accessibilityLabel("Compression progress")
                    .accessibilityValue("\(Int(model.progress * 100)) percent")
            }
            ToolActionBar(
                title: actionTitle,
                detail: actionDetail
            ) {
                if model.isRunning {
                    ToolCancelButton(action: model.cancel)
                } else {
                    Button {
                        model.start(cjpeg: dependencies.cjpegURL, exiftool: dependencies.exiftoolURL)
                    } label: {
                        Label(
                            model.images.isEmpty ? "Compress Photos" : "Compress \(model.images.count.formatted()) Photos",
                            systemImage: "play.fill"
                        )
                        .frame(minWidth: PFLayout.primaryActionMinimumWidth)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(
                        dependencies.cjpegURL == nil || (model.metadataPolicy != .removeAll && dependencies.exiftoolURL == nil)
                            || model.images.isEmpty || model.outputFolder == nil
                    )
                    .keyboardShortcut(.return, modifiers: [.command])
                    .primaryActionHover()
                }
            }
        }
    }

    private var actionTitle: String {
        if model.isRunning {
            return "Compressing \(Int(model.progress * Double(max(model.images.count, 1)))) of \(model.images.count)"
        }
        if !model.resultMessage.isEmpty { return model.resultMessage }
        if model.isScanning { return "Scanning selected folder…" }
        if model.images.isEmpty { return "Add photos to begin" }
        if model.outputFolder == nil { return "Choose an output destination" }
        if !dependencies.isReady { return "Dependencies need attention" }
        return "Ready to compress offline"
    }

    private var actionDetail: String {
        if !model.currentFile.isEmpty { return model.currentFile }
        if model.images.isEmpty { return "Drop photos or choose a folder; originals stay untouched." }
        return model.selectionSummary
    }
}

private struct CompressionSizeSummary: View {
    let beforeBytes: Int64
    let afterBytes: Int64
    let changeBytes: Int64
    let changePercentage: Int

    private var accent: Color {
        if changeBytes > 0 { return PFTheme.success }
        if changeBytes < 0 { return PFTheme.warning }
        return .secondary
    }
    private var changeIcon: String {
        if changeBytes > 0 { return "arrow.down.right" }
        if changeBytes < 0 { return "arrow.up.right" }
        return "equal"
    }
    private var changeDescription: String {
        if changeBytes > 0 {
            return "Saved \(ByteCountFormatter.string(for: changeBytes)) · \(changePercentage)% smaller"
        }
        if changeBytes < 0 {
            return "\(ByteCountFormatter.string(for: abs(changeBytes))) larger · \(abs(changePercentage))% increase"
        }
        return "No size change"
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            horizontalSummary
            wrappedSummary
        }
        .padding(.horizontal, PFSpacing.control)
        .padding(.vertical, 10)
        .background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: PFRadius.control, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Total size before \(ByteCountFormatter.string(for: beforeBytes)), after \(ByteCountFormatter.string(for: afterBytes)). \(changeDescription)."
        )
    }

    private var horizontalSummary: some View {
        HStack(spacing: PFSpacing.control) {
            Text("TOTAL SIZE")
                .font(BrandTypography.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Rectangle()
                .fill(PFTheme.border)
                .frame(width: 1, height: 22)
                .accessibilityHidden(true)
            HStack(alignment: .firstTextBaseline, spacing: PFSpacing.compact) {
                sizePair(label: "Before", bytes: beforeBytes, emphasized: false)
                Image(systemName: "arrow.right")
                    .font(BrandTypography.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                sizePair(label: "After", bytes: afterBytes, emphasized: true)
            }
            Rectangle()
                .fill(PFTheme.border)
                .frame(width: 1, height: 22)
                .accessibilityHidden(true)
            changeLabel
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var wrappedSummary: some View {
        VStack(alignment: .leading, spacing: PFSpacing.compact) {
            Text("TOTAL SIZE")
                .font(BrandTypography.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: PFSpacing.compact) {
                sizePair(label: "Before", bytes: beforeBytes, emphasized: false)
                Image(systemName: "arrow.right")
                    .font(BrandTypography.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                sizePair(label: "After", bytes: afterBytes, emphasized: true)
            }
            changeLabel
        }
    }

    private var changeLabel: some View {
        Label(changeDescription, systemImage: changeIcon)
            .font(BrandTypography.caption.weight(.semibold))
            .foregroundStyle(accent)
    }

    private func sizePair(label: String, bytes: Int64, emphasized: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: PFSpacing.micro) {
            Text(label)
                .font(BrandTypography.caption2)
                .foregroundStyle(.secondary)
            Text(ByteCountFormatter.string(for: bytes))
                .font(BrandTypography.subheadline.weight(emphasized ? .bold : .medium))
                .monospacedDigit()
        }
    }
}
