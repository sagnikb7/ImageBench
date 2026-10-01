import SwiftUI

@main
struct ImageBenchApp: App {
    @StateObject private var dependencies = DependencyManager()

    init() {
        BrandTypography.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .font(BrandTypography.body)
                .environmentObject(dependencies)
                .frame(minWidth: PFLayout.minimumWindow.width, minHeight: PFLayout.minimumWindow.height)
                .task { await dependencies.refreshAndBootstrapIfPossible() }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))
        .defaultSize(width: PFLayout.defaultWindow.width, height: PFLayout.defaultWindow.height)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check Dependencies…") { Task { await dependencies.install() } }
                    .keyboardShortcut("d", modifiers: [.command, .shift])
            }
        }
    }
}
