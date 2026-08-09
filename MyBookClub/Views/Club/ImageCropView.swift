//
//  ImageCropView.swift
//  MyBookClub
//

import SwiftUI
import UIKit

/// Full-screen crop/reposition UI for club cover photos.
/// Locked to 3:1 to match the "Recommended: 1200×400px" guidance in CreateClubView.
/// The image passed in must already be orientation-normalized (.up) — the pixel-space
/// crop math assumes UIImage.size and UIImage.cgImage agree.
struct ImageCropView: View {
    let image: UIImage
    let onCancel: () -> Void
    let onCrop: (UIImage) -> Void

    private static let aspectRatio: CGFloat = 3.0
    private static let maxZoom: CGFloat = 4.0
    private static let outputRenderScale: CGFloat = 3.0
    private static let maxOutputWidth: CGFloat = 1600

    @State private var cropSize: CGSize = .zero
    @State private var zoom: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var zoomAtGestureStart: CGFloat = 1.0
    @State private var offsetAtGestureStart: CGSize = .zero

    private var imageSize: CGSize { image.size }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let maxWidthByHeight = geo.size.height * Self.aspectRatio
                let windowWidth = min(geo.size.width, maxWidthByHeight)
                let windowSize = CGSize(width: windowWidth, height: windowWidth / Self.aspectRatio)

                ZStack {
                    Color.black.ignoresSafeArea()

                    Image(uiImage: image)
                        .resizable()
                        .frame(width: imageSize.width, height: imageSize.height)
                        .scaleEffect(baseScale() * zoom)
                        .offset(offset)
                        .frame(width: windowSize.width, height: windowSize.height)
                        .clipped()
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)

                    dimmingOverlay(fullSize: geo.size, windowSize: windowSize)

                    Rectangle()
                        .strokeBorder(Color.white, lineWidth: 2)
                        .frame(width: windowSize.width, height: windowSize.height)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        .allowsHitTesting(false)

                    Text("Drag to reposition • Pinch to zoom")
                        .font(.appCaption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(.black.opacity(0.5), in: Capsule())
                        .position(x: geo.size.width / 2, y: geo.size.height / 2 + windowSize.height / 2 + Spacing.xxl)
                        .allowsHitTesting(false)
                }
                .contentShape(Rectangle())
                .gesture(panAndZoomGesture())
                .onAppear { cropSize = windowSize }
                .onChange(of: windowSize) { _, new in cropSize = new }
            }
            .navigationTitle("Reposition Cover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { onCancel() }
                        .tint(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Use Photo") { onCrop(renderCroppedImage()) }
                        .tint(.white)
                        .fontWeight(.semibold)
                }
            }
        }
        // Scoped to this view only — .preferredColorScheme would propagate up and
        // leave the presenting sheet stuck in dark mode after dismissal.
        .environment(\.colorScheme, .dark)
    }

    // MARK: - Dimming

    private func dimmingOverlay(fullSize: CGSize, windowSize: CGSize) -> some View {
        let stripHeight = max(0, (fullSize.height - windowSize.height) / 2)
        return VStack(spacing: 0) {
            Color.black.opacity(0.65).frame(height: stripHeight)
            Color.clear.frame(height: windowSize.height)
            Color.black.opacity(0.65).frame(height: stripHeight)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Scale math

    /// Zoom level at which the image exactly covers the crop window (scaledToFill equivalent).
    private func baseScale() -> CGFloat {
        guard imageSize.width > 0, imageSize.height > 0, cropSize != .zero else { return 1 }
        return max(cropSize.width / imageSize.width, cropSize.height / imageSize.height)
    }

    /// Clamps a pan offset so the image can never be dragged to reveal a gap.
    private func clampedOffset(_ proposed: CGSize, zoom: CGFloat) -> CGSize {
        let scale = baseScale() * zoom
        let scaledImageSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let maxX = max(0, (scaledImageSize.width  - cropSize.width)  / 2)
        let maxY = max(0, (scaledImageSize.height - cropSize.height) / 2)
        return CGSize(
            width:  min(max(proposed.width,  -maxX), maxX),
            height: min(max(proposed.height, -maxY), maxY)
        )
    }

    // MARK: - Gestures

    private func panAndZoomGesture() -> some Gesture {
        // Each gesture reads its own start-snapshot: gesture values are cumulative
        // since that gesture began, and SimultaneousGesture lets them start/end
        // independently — a shared "last value" would reset pan when a pinch ends.
        let magnification = MagnificationGesture()
            .onChanged { value in
                let newZoom = min(max(zoomAtGestureStart * value, 1.0), Self.maxZoom)
                zoom = newZoom
                offset = clampedOffset(offset, zoom: newZoom)
            }
            .onEnded { _ in zoomAtGestureStart = zoom }

        let drag = DragGesture()
            .onChanged { value in
                let proposed = CGSize(
                    width:  offsetAtGestureStart.width  + value.translation.width,
                    height: offsetAtGestureStart.height + value.translation.height
                )
                offset = clampedOffset(proposed, zoom: zoom)
            }
            .onEnded { _ in offsetAtGestureStart = offset }

        return SimultaneousGesture(magnification, drag)
    }

    // MARK: - Final crop render

    /// Maps the on-screen crop window back to a pixel rect in the original image
    /// (screen point P = image point Q * scale + offset, so Q = (P - offset) / scale),
    /// crops it, and renders a fixed-size 3:1 output.
    private func renderCroppedImage() -> UIImage {
        guard let cgImage = image.cgImage, imageSize.width > 0, imageSize.height > 0, cropSize != .zero else {
            return image
        }

        let scale = baseScale() * zoom
        let cropWidthInImageSpace  = cropSize.width  / scale
        let cropHeightInImageSpace = cropSize.height / scale
        let originX = imageSize.width  / 2 - cropWidthInImageSpace  / 2 - offset.width  / scale
        let originY = imageSize.height / 2 - cropHeightInImageSpace / 2 - offset.height / scale

        let pixelScale = image.scale
        var pixelRect = CGRect(
            x: originX * pixelScale,
            y: originY * pixelScale,
            width: cropWidthInImageSpace * pixelScale,
            height: cropHeightInImageSpace * pixelScale
        ).integral

        let bounds = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
        pixelRect = pixelRect.intersection(bounds)

        guard pixelRect.width > 1, pixelRect.height > 1,
              let croppedCG = cgImage.cropping(to: pixelRect) else {
            return image
        }

        let cropped = UIImage(cgImage: croppedCG, scale: image.scale, orientation: .up)

        var outputWidth = cropSize.width * Self.outputRenderScale
        outputWidth = min(outputWidth, Self.maxOutputWidth)
        let outputSize = CGSize(width: outputWidth, height: (outputWidth / Self.aspectRatio).rounded())

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: outputSize, format: format)
        return renderer.image { _ in
            cropped.draw(in: CGRect(origin: .zero, size: outputSize))
        }
    }
}
