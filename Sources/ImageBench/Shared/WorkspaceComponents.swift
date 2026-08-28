import SwiftUI

/// Owns the chrome shared by every processing tool while leaving task content explicit.
struct ToolWorkspace<Content: View, ActionBar: View>: View {
    let title: String
    let subtitle: String
    let navigationTitle: String
    private let content: Content
    private let actionBar: ActionBar

    init(
        title: String,
        subtitle: String,
        navigationTitle: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder actionBar: () -> ActionBar
    ) {
        self.title = title
        self.subtitle = subtitle
        self.navigationTitle = navigationTitle
        self.content = content()
        self.actionBar = actionBar()
    }

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: title, subtitle: subtitle)
                .padding(.horizontal, PFSpacing.screen)
                .padding(.top, PFSpacing.screen)
                .padding(.bottom, PFSpacing.section)
            content
            Divider()
            actionBar
                .padding(.horizontal, PFSpacing.screen)
                .padding(.vertical, 13)
                .background(.bar)
        }
        .background(PFTheme.canvas)
        .navigationTitle(navigationTitle)
    }
}

struct PreviewInspectorLayout<Preview: View, Inspector: View>: View {
    private let preview: Preview
    private let inspector: Inspector

    init(@ViewBuilder preview: () -> Preview, @ViewBuilder inspector: () -> Inspector) {
        self.preview = preview()
        self.inspector = inspector()
    }

    var body: some View {
        HStack(alignment: .top, spacing: PFSpacing.section) {
            preview
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            inspector
                .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(.horizontal, PFSpacing.screen)
        .padding(.top, PFSpacing.card)
        .padding(.bottom, PFSpacing.card)
        .frame(maxHeight: .infinity)
    }
}

struct PreviewStage<Content: View>: View {
    let isCanvasVisible: Bool
    private let content: Content

    init(isCanvasVisible: Bool = true, @ViewBuilder content: () -> Content) {
        self.isCanvasVisible = isCanvasVisible
        self.content = content()
    }

    var body: some View {
        ZStack { content }
            .frame(minHeight: PFLayout.previewMinimumHeight)
            .background(
                isCanvasVisible ? PFTheme.mediaStageSurface : .clear,
                in: RoundedRectangle(cornerRadius: PFRadius.inset, style: .continuous)
            )
            .overlay {
                if isCanvasVisible {
                    RoundedRectangle(cornerRadius: PFRadius.inset, style: .continuous)
                        .stroke(PFTheme.border, lineWidth: 1)
                }
            }
    }
}

struct FolderPickerRow: View {
    let folder: URL?
    let placeholder: String
    let action: () -> Void

    var body: some View {
        HStack {
            Label(folder?.lastPathComponent ?? placeholder, systemImage: "folder")
                .lineLimit(1)
            Spacer()
            Button("Choose…", action: action)
        }
        .padding(10)
        .background(PFTheme.secondarySurface.opacity(0.65), in: RoundedRectangle(cornerRadius: PFRadius.control, style: .continuous))
    }
}

struct SelectedImageRow: View {
    let input: URL
    let change: () -> Void

    var body: some View {
        HStack {
            Label(input.lastPathComponent, systemImage: "photo.fill")
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
            Spacer()
            Button("Change…", action: change)
        }
    }
}

struct AsyncThumbnailView: View {
    let url: URL
    let maxPixelSize: Int
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
        .task(id: url) {
            image = nil
            do {
                let loaded = try await Task.detached(priority: .utility) {
                    try ImageRenderer.thumbnail(at: url, maxPixelSize: maxPixelSize)
                }.value
                try Task.checkCancellation()
                image = loaded
            } catch {
                // The placeholder is the correct fallback for cancellation and unreadable input.
            }
        }
    }
}

struct ImageDropPrompt: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: PFSpacing.compact) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(PFTheme.coral)
                .accessibilityHidden(true)
            Text(title).font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct ToolCancelButton: View {
    let action: () -> Void

    var body: some View {
        Button("Cancel", role: .destructive, action: action)
            .controlSize(.large)
            .keyboardShortcut(.cancelAction)
            .primaryActionHover(color: PFTheme.danger)
    }
}

struct ToolActionBar<Actions: View>: View {
    let title: String
    let detail: String
    private let actions: Actions

    init(title: String, detail: String, @ViewBuilder actions: () -> Actions) {
        self.title = title
        self.detail = detail
        self.actions = actions()
    }

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            actions
        }
    }
}

struct InstagramSplitHint: View {
    let parts: Int

    private var message: String? {
        switch parts {
        case 2:
            "For two seamless portrait posts, prepare a 16:10 canvas for 4:5 cards, or 3:2 for Instagram’s newer 3:4 format."
        case 3:
            "For three seamless portrait posts, prepare a 12:5 canvas for 4:5 cards, or 9:4 for Instagram’s newer 3:4 format."
        default:
            nil
        }
    }

    var body: some View {
        if let message {
            Label(message, systemImage: "lightbulb")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(PFSpacing.control)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(PFTheme.quietSelection, in: RoundedRectangle(cornerRadius: PFRadius.control))
                .accessibilityLabel("Instagram tip: \(message)")
        }
    }
}
