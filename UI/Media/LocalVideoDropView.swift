import SwiftUI
import AppKit

struct LocalVideoDropView: View {
    @EnvironmentObject var videoStore: VideoLibraryStore

    @State private var showSuccess = false
    @State private var isHovering = false

    var body: some View {
        Group {
            if showSuccess {
                HStack {
                    Spacer()
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                        .transition(.scale.combined(with: .opacity))
                    Spacer()
                }
                .frame(width: 36, height: 36)
                .background(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 100))
                .overlay(
                    RoundedRectangle(cornerRadius: 100)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 5)
            } else {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add a Private Video")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Drop your .mp4 video or click to select")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.leading, 4)

                    Spacer()

                    Button(action: openFileDialog) {
                        Text("Select")
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(12)
                .frame(height: 56)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(isHovering ? Color.blue : Color.white.opacity(0.12), lineWidth: 1)
                        .animation(.easeInOut(duration: 0.25), value: isHovering)
                )
                .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 5)
                .onDrop(of: ["public.file-url"], isTargeted: $isHovering, perform: handleDrop)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showSuccess)
        .fixedSize()
    }

    private func openFileDialog() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["mp4"]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            importVideo(from: url)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
            if let data = item as? Data,
               let url = URL(dataRepresentation: data, relativeTo: nil),
               url.pathExtension.lowercased() == "mp4" {
                DispatchQueue.main.async {
                    importVideo(from: url)
                }
            }
        }

        return true
    }

    private func importVideo(from url: URL) {
        videoStore.importLocalVideo(from: url)
        withAnimation {
            showSuccess = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showSuccess = false
            }
        }
    }
}
