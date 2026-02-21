import SwiftUI

struct ZoomableImageView: View {
    let uiImage: UIImage
    var onOpen: (() -> Void)? = nil
    @State private var showFullscreen = false
    
    var body: some View {
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 200)
            .overlay(alignment: .bottomTrailing) {
                Label("Tap to zoom", systemImage: "magnifyingglass")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(8)
            }
            .onTapGesture {
                onOpen?()
                showFullscreen = true
            }
            .accessibilityLabel("Reference image")
            .accessibilityHint("Double tap to open fullscreen and zoom")
            .fullScreenCover(isPresented: $showFullscreen) {
                FullscreenImageViewer(uiImage: uiImage, isPresented: $showFullscreen)
            }
    }
}

private struct FullscreenImageViewer: View {
    let uiImage: UIImage
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = lastScale * value
                        }
                        .onEnded { _ in
                            lastScale = scale
                            if scale < 1 {
                                withAnimation { scale = 1; lastScale = 1 }
                            }
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation {
                        if scale > 1 {
                            scale = 1
                            lastScale = 1
                            offset = .zero
                            lastOffset = .zero
                        } else {
                            scale = 2
                            lastScale = 2
                        }
                    }
                }
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()
                Text("Pinch to zoom. Drag to inspect details. Double tap to reset zoom.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    if let previewImage = UIImage(systemName: "airplane") {
        ZoomableImageView(uiImage: previewImage)
    } else {
        Text("Preview image unavailable")
    }
}
