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
            SheetTitle(title: "Settings", subtitle: "Choose how ImageBench opens and looks.", dismiss: dismiss)
            ScrollView {
                VStack(alignment: .leading, spacing: PFSpacing.card) {
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
                                .font(BrandTypography.caption)
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
                                .font(BrandTypography.caption)
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
                }
                .padding(4)
            }
        }
        .padding(24)
        .frame(width: 560, height: 500)
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
        VStack(alignment: .leading, spacing: PFSpacing.card) {
            HStack {
                Spacer()
                SheetCloseButton(action: dismiss.callAsFunction)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: PFSpacing.card) {
                    VStack(spacing: PFSpacing.compact) {
                        BrandIcon(size: 92)
                        Text(info.name)
                            .font(BrandTypography.largeTitle.bold())
                            .accessibilityAddTraits(.isHeader)
                        Text(info.versionLine)
                            .font(BrandTypography.caption)
                            .foregroundStyle(.secondary)
                        Text("A private, offline image workbench for macOS.")
                            .font(BrandTypography.headline)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, PFSpacing.compact)

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: PFSpacing.control) {
                            SectionHeading("Private by design")
                            Text(
                                "Processing stays on this Mac, and original images are never modified. ImageBench has no analytics, ads, or image uploads. External links and maps open only when you choose."
                            )
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: PFSpacing.control) {
                            SectionHeading("Open source")
                            Text("ImageBench is free to use under the MIT License.")
                                .foregroundStyle(.secondary)
                            HStack(spacing: PFSpacing.section) {
                                Link("View on GitHub", destination: AppInfo.repositoryURL)
                                Link("Report an Issue", destination: AppInfo.issuesURL)
                            }
                            HStack(spacing: PFSpacing.section) {
                                Button("License") { openResource("LICENSE", extension: nil) }
                                Button("Third-Party Notices") { openResource("ThirdPartyNotices", extension: "md") }
                            }
                        }
                    }
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: PFSpacing.control) {
                            SectionHeading("Bundled tools")
                            StatusPill(
                                icon: "checkmark.shield.fill",
                                text: dependencies.isReady ? "Offline tools ready" : "Dependencies need attention",
                                color: dependencies.isReady ? PFTheme.success : PFTheme.warning
                            )
                            Text("mozjpeg 4.1.5 • ExifTool 13.25")
                                .font(BrandTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(4)
            }
        }
        .padding(PFSpacing.screen)
        .frame(width: 560, height: 620)
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
                Text(title).font(BrandTypography.title2.bold())
                Text(subtitle).font(BrandTypography.subheadline).foregroundStyle(.secondary)
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
