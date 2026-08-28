import Foundation
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var appearance: AppearancePreference
    @Binding var startupToolName: String
    @ObservedObject var watermarkModel: WatermarkViewModel
    @State private var confirmsPresetReset = false

    var body: some View {
        VStack(alignment: .leading, spacing: PFSpacing.card) {
            SheetTitle(title: "Settings", subtitle: "Make the workspace feel right on your Mac.", dismiss: dismiss)
            SurfaceCard {
                VStack(alignment: .leading, spacing: PFSpacing.control) {
                    SectionHeading("Appearance")
                    Picker("Theme", selection: $appearance) {
                        ForEach(AppearancePreference.allCases) { preference in
                            Text(preference.rawValue).tag(preference)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    Text("System follows your Mac automatically. Light and Dark keep ImageBench in the selected appearance.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            SurfaceCard {
                VStack(alignment: .leading, spacing: PFSpacing.control) {
                    SectionHeading("Startup")
                    LabeledContent("Open ImageBench to") {
                        Picker("Open ImageBench to", selection: $startupToolName) {
                            ForEach(AppTool.allCases) { tool in
                                Text(tool.rawValue).tag(tool.rawValue)
                            }
                        }
                        .labelsHidden()
                        .frame(width: PFLayout.selectionFieldWidth)
                    }
                    Text("The selected module opens first the next time ImageBench launches.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            SurfaceCard {
                VStack(alignment: .leading, spacing: PFSpacing.control) {
                    SectionHeading("Watermark Presets")
                    Text("\(watermarkModel.presets.count) of 4 preset slots are saved in Application Support.")
                        .foregroundStyle(.secondary)
                    Button("Reset All Watermark Presets…", role: .destructive) {
                        confirmsPresetReset = true
                    }
                    .disabled(watermarkModel.presets.isEmpty)
                }
            }
            SurfaceCard {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeading("Privacy")
                    Label("All image processing stays on this Mac", systemImage: "lock.shield.fill")
                        .foregroundStyle(PFTheme.success)
                    Text("ImageBench has no analytics, ads, uploads, or runtime network calls. Original files are never modified.")
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(24)
        .frame(width: 560)
        .frame(minHeight: 600)
        .confirmationDialog("Reset All Watermark Presets?", isPresented: $confirmsPresetReset, titleVisibility: .visible) {
            Button("Reset All Presets", role: .destructive) {
                Task { await watermarkModel.resetAllPresets() }
            }
        } message: {
            Text("This removes all saved watermark presets and their app-managed images.")
        }
        .task {
            await watermarkModel.loadPresets()
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dependencies: DependencyManager
    private let info = AppInfo.current

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                SheetCloseButton(action: dismiss.callAsFunction)
            }
            BrandIcon(size: 92)
            VStack(spacing: 4) {
                Text(info.name).font(.largeTitle.bold())
                Text(info.versionLine).foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            Text("A private, offline image workbench for macOS.")
                .font(.headline)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("A private, offline image workbench for macOS.")
            StatusPill(
                icon: "checkmark.shield.fill", text: dependencies.isReady ? "Offline tools ready" : "Dependencies need attention",
                color: dependencies.isReady ? PFTheme.success : PFTheme.warning
            )
            .accessibilityElement(children: .combine)
            VStack(spacing: 4) {
                Text("Bundled for release")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("mozjpeg 4.1.5 • ExifTool 13.25")
                    .font(.caption.monospaced())
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Bundled dependencies: mozjpeg 4.1.5, ExifTool 13.25")
            HStack {
                Button("Third-Party Notices") { openResource("ThirdPartyNotices", extension: "md") }
                Button("License") { openResource("LICENSE", extension: nil) }
            }
            Text("Open source under the MIT License")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Open source under the MIT License")
        }
        .padding(28)
        .frame(width: 520, height: 500)
        .accessibilityElement(children: .contain)
    }

    private func openResource(_ name: String, extension ext: String?) {
        let candidates = [Bundle.main.resourceURL, Bundle.module.resourceURL].compactMap { $0 }
        let filename = ext.map { "\(name).\($0)" } ?? name
        let release = candidates.map { $0.appendingPathComponent(filename) }
        let development = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(filename)
        if let url = (release + [development]).first(where: { FileManager.default.fileExists(atPath: $0.path) }) {
            WorkspaceFileActions.open(url)
        }
    }
}

private struct SheetTitle: View {
    let title: String
    let subtitle: String
    let dismiss: DismissAction

    var body: some View {
        HStack(alignment: .top, spacing: PFSpacing.control) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.title2.bold())
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            SheetCloseButton(action: dismiss.callAsFunction)
        }
    }
}

private struct SheetCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 32, height: 32)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .background(PFTheme.secondarySurface, in: Circle())
        .overlay { Circle().stroke(PFTheme.border) }
        .contentShape(Circle())
        .keyboardShortcut(.cancelAction)
        .help("Close")
        .accessibilityLabel("Close")
        .pointingHandCursor()
    }
}
