//
//  ISBNScannerView.swift
//  MyBookClub
//

import SwiftUI
import VisionKit
import Vision
import AVFoundation

struct ISBNScannerView: View {
    let onScan: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var authStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

    static var isDeviceCapable: Bool { DataScannerViewController.isSupported }

    var body: some View {
        NavigationStack {
            content
                .background(Color.black.ignoresSafeArea())
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { dismiss() }.tint(.white)
                    }
                }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var content: some View {
        if !DataScannerViewController.isSupported {
            ContentUnavailableView(
                "Scanning Unavailable",
                systemImage: "barcode.viewfinder",
                description: Text("Barcode scanning isn't supported on this device. You can still search by typing the ISBN.")
            ).foregroundStyle(.white)
        } else {
            switch authStatus {
            case .authorized:
                if DataScannerViewController.isAvailable {
                    scannerState
                } else {
                    ContentUnavailableView(
                        "Camera Unavailable",
                        systemImage: "camera.fill",
                        description: Text("Try again in a moment, or search by typing the ISBN.")
                    ).foregroundStyle(.white)
                }
            case .notDetermined:
                ProgressView().tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .task { authStatus = await AVCaptureDevice.requestAccess(for: .video) ? .authorized : .denied }
            default:
                ContentUnavailableView {
                    Label("Camera Access Needed", systemImage: "camera.fill")
                } description: {
                    Text("MyBookClub needs camera access to scan a barcode. You can still search by typing the ISBN.")
                } actions: {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }.buttonStyle(.borderedProminent)
                }.foregroundStyle(.white)
            }
        }
    }

    private var scannerState: some View {
        ZStack(alignment: .bottom) {
            DataScannerRepresentable { code in
                onScan(code)
                dismiss()
            }
            .ignoresSafeArea()

            Text("Point your camera at the barcode on the back of the book")
                .font(.appCaption)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .background(.black.opacity(0.65), in: Capsule())
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxl)
        }
    }
}

// MARK: - DataScannerViewController bridge

private struct DataScannerRepresentable: UIViewControllerRepresentable {
    let onScan: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.ean13])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: false,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onScan: (String) -> Void
        private var didReport = false

        init(onScan: @escaping (String) -> Void) { self.onScan = onScan }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard !didReport else { return }
            for item in addedItems {
                guard case .barcode(let barcode) = item, let payload = barcode.payloadStringValue else { continue }
                didReport = true
                dataScanner.stopScanning()
                onScan(payload)
                return
            }
        }
    }
}
