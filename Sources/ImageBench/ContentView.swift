import SwiftUI

enum AppTool: String, CaseIterable, Identifiable {
    case compressor = "Bulk Compressor"
    case watermark = "Watermark Studio"
    case splitter = "Image Splitter"
    case filler = "Aspect Ratio Filler"
    case exif = "EXIF Viewer"

    var id: Self { self }
    var icon: String {
        switch self {
        case .compressor: "photo.stack"
        case .watermark: "signature"
        case .splitter: "rectangle.split.3x1"
        case .filler: "aspectratio"
        case .exif: "camera.metering.matrix"
        }
    }
}

struct ContentView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selection: AppTool? = .compressor
    @State private var showsSettings = false
    @State private var showsAbout = false
    @State private var hoveredTool: AppTool?
    @State private var hoveredSidebarAction: String?
    @State private var isSidebarVisible = true
    @AppStorage("appearancePreference") private var appearance = AppearancePreference.system
    @AppStorage("startupTool") private var startupToolName = AppTool.compressor.rawValue
    @StateObject private var compressorModel = CompressorViewModel()
    @StateObject private var watermarkModel = WatermarkViewModel()
    @StateObject private var splitterModel = SplitterViewModel()
    @StateObject private var fillerModel = AspectFillerViewModel()
    @StateObject private var exifModel = ExifViewerViewModel()

    init() {
        let savedTool = UserDefaults.standard.string(forKey: "startupTool").flatMap(AppTool.init(rawValue:)) ?? .compressor
        _selection = State(initialValue: savedTool)
    }

    var body: some View {
        HStack(spacing: 0) {
            if isSidebarVisible {
                sidebar
                    .frame(width: PFLayout.sidebarWidth)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                Divider()
            }
            detail
        }
        .animation(reduceMotion ? nil : PFMotion.quick, value: isSidebarVisible)
        .tint(PFTheme.action)
        .preferredColorScheme(appearance.colorScheme)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    isSidebarVisible.toggle()
                } label: {
                    Image(systemName: "sidebar.left")
                }
                .keyboardShortcut("s", modifiers: [.command, .control])
                .help(isSidebarVisible ? "Hide Sidebar" : "Show Sidebar")
                .accessibilityLabel(isSidebarVisible ? "Hide Sidebar" : "Show Sidebar")
            }
        }
        .sheet(isPresented: $showsSettings) {
            SettingsView(
                appearance: $appearance,
                startupToolName: $startupToolName,
                watermarkModel: watermarkModel
            )
        }
        .sheet(isPresented: $showsAbout) { AboutView() }
        .task {
            if ProcessInfo.processInfo.environment["IMAGEBENCH_SHOW_SETTINGS"] == "1" { showsSettings = true }
            if ProcessInfo.processInfo.environment["IMAGEBENCH_SHOW_ABOUT"] == "1" { showsAbout = true }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                SidebarBrandMark(size: 38)
                BrandWordmark()
            }
            .padding(.horizontal, 14)
            .padding(.top, 18)
            .padding(.bottom, 26)
            VStack(spacing: 5) {
                ForEach(AppTool.allCases) { tool in sidebarRow(tool) }
            }
            .padding(.horizontal, 10)
            Spacer()
            Divider().padding(.horizontal, 16)
            VStack(alignment: .leading, spacing: 5) {
                sidebarAction("Settings", icon: "gearshape", action: { showsSettings = true })
                sidebarAction("About ImageBench", icon: "info.circle", action: { showsAbout = true })
            }
            .padding(10)
            Label("Private & offline", systemImage: "lock.shield")
                .font(BrandTypography.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .help("All image processing stays on this Mac")
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
        }
        .background(PFTheme.canvas)
    }

    private var detail: some View {
        Group {
            switch selection ?? .compressor {
            case .compressor: CompressorView(model: compressorModel)
            case .watermark: WatermarkView(model: watermarkModel)
            case .splitter: SplitterView(model: splitterModel)
            case .filler: AspectFillerView(model: fillerModel)
            case .exif: ExifViewerView(model: exifModel)
            }
        }
        .id(selection ?? .compressor)
        .transition(.opacity)
        .animation(reduceMotion ? nil : PFMotion.quick, value: selection)
    }

    private func sidebarRow(_ tool: AppTool) -> some View {
        Button {
            if reduceMotion {
                selection = tool
            } else {
                withAnimation(PFMotion.quick) { selection = tool }
            }
        } label: {
            Label(tool.rawValue, systemImage: tool.icon)
                .font(BrandTypography.body.weight(selection == tool ? .semibold : .regular))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 11)
                .padding(.vertical, 10)
                .background(
                    sidebarBackground(for: tool),
                    in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onHover { isHovered in
            if isHovered {
                hoveredTool = tool
            } else if hoveredTool == tool {
                hoveredTool = nil
            }
        }
        .pointingHandCursor()
        .accessibilityAddTraits(selection == tool ? .isSelected : [])
    }

    private func sidebarAction(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(
                    hoveredSidebarAction == title ? PFTheme.hoverSurface : .clear,
                    in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onHover { isHovered in
            if isHovered {
                hoveredSidebarAction = title
            } else if hoveredSidebarAction == title {
                hoveredSidebarAction = nil
            }
        }
        .pointingHandCursor()
    }

    private func sidebarBackground(for tool: AppTool) -> Color {
        if selection == tool {
            return hoveredTool == tool ? PFTheme.sidebarSelectionHover : PFTheme.sidebarSelection
        }
        return hoveredTool == tool ? PFTheme.hoverSurface : .clear
    }
}
