import SwiftUI

/// Popover content for the "Bild-Export" button: pick a format, optionally
/// cap the long edge, and (for JPEG) a quality — then export the current
/// image selection to the desktop via ImageExportService.
struct ImageExportOptionsView: View {
    let urls: [URL]
    let onDone: () -> Void

    @State private var format: ImageExportFormat = .jpeg
    @State private var resizeEnabled = true
    @State private var maxDimension: Double = 1600
    @State private var quality: Double = 0.8

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(urls.count) Bild\(urls.count == 1 ? "" : "er") exportieren")
                .font(.headline)

            Picker("Format", selection: $format) {
                ForEach(ImageExportFormat.allCases) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Verkleinern auf max. \(Int(maxDimension)) px (lange Kante)", isOn: $resizeEnabled)
            if resizeEnabled {
                Slider(value: $maxDimension, in: 400...4000, step: 100)
            }

            if format == .jpeg {
                Text("Qualität: \(Int(quality * 100)) %")
                Slider(value: $quality, in: 0.3...1.0)
            }

            Button("Exportieren") {
                ImageExportService.export(
                    urls: urls,
                    format: format,
                    maxDimension: resizeEnabled ? CGFloat(maxDimension) : nil,
                    quality: CGFloat(quality)
                )
                onDone()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(16)
        .frame(width: 260)
    }
}
