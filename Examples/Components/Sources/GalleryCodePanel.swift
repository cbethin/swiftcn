import SwiftUI
import SwiftCN
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct GalleryCodePanel: View {
    let source: String
    var fileName = "Example.swift"
    var fillsWidth = false
    var isVisible = true
    @State private var copied = false
    @State private var copyReset: Task<Void, Never>?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // Keep the focus tree stable across workspace modes, without preparing hidden code.
        let document = isVisible ? GalleryCodeDocument.cached(source) : nil
        CNCard("shadow-none rounded-xl") {
            HStack(spacing: 8) {
                Image(systemName: "swift").foregroundStyle(.orange).accessibilityHidden(true)
                Text(fileName).font(.system(size: 11, weight: .medium, design: .monospaced))
                    .lineLimit(1).truncationMode(.middle)
                Spacer(minLength: 0)
                CNButton(variant: .ghost, size: .small, classes: "px-2", action: copy) {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc").font(.system(size: 11))
                        .contentTransition(reduceMotion ? .identity : .symbolEffect(.replace))
                }
                .accessibilityLabel(copied ? "Swift code copied" : "Copy Swift code")
                .help(copied ? "Copied" : "Copy Swift code")
                .galleryChrome()
            }.padding(.horizontal, 16).frame(height: 48)
            CNSeparator()
            ScrollView([.horizontal, .vertical]) {
                HStack(alignment: .top, spacing: 18) {
                    Text(document?.lineNumbers ?? "")
                        .foregroundStyle(.secondary.opacity(0.5))
                        .multilineTextAlignment(.trailing)
                        .accessibilityHidden(true)
                        .textSelection(.disabled)
                    Text(document?.highlighted(dark: scheme == .dark) ?? AttributedString())
                        .textSelection(.enabled)
                        .fixedSize(horizontal: true, vertical: true)
                }
                .font(.system(size: 11, design: .monospaced)).lineSpacing(5)
                .padding(20).frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(height: fillsWidth ? 510 : 390)
            .tw("bg-muted")
            CNSeparator()
            HStack(spacing: 6) {
                Text("\(document?.lineCount ?? 0) lines · Swift")
                Spacer()
                Text(copied ? "Copied to clipboard" : "Complete example")
            }.font(.system(size: 10)).tw("text-mutedForeground")
                .padding(.horizontal, 16).frame(height: 36)
        }
        .onDisappear { copyReset?.cancel() }
        .onChange(of: source) { _, _ in copyReset?.cancel(); copied = false }
    }

    private func copy() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(source, forType: .string)
        #else
        UIPasteboard.general.string = source
        #endif
        copied = true
        copyReset?.cancel()
        copyReset = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            copied = false
        }
    }
}

/// Immutable source metadata and lazily cached color variants, shared across repeated renders.
@MainActor
final class GalleryCodeDocument {
    private static let cache: NSCache<NSString, GalleryCodeDocument> = {
        let cache = NSCache<NSString, GalleryCodeDocument>()
        cache.countLimit = 96
        return cache
    }()
    let source: String
    let lineCount: Int
    let lineNumbers: String
    private var variants: [Bool: AttributedString] = [:]

    static func cached(_ source: String) -> GalleryCodeDocument {
        let key = source as NSString
        if let document = cache.object(forKey: key) { return document }
        let document = GalleryCodeDocument(source)
        cache.setObject(document, forKey: key)
        return document
    }

    private init(_ source: String) {
        self.source = source
        lineCount = source.components(separatedBy: "\n").count
        lineNumbers = (1...max(1, lineCount)).map(String.init).joined(separator: "\n")
    }

    func highlighted(dark: Bool) -> AttributedString {
        if let cached = variants[dark] { return cached }
        let result = GallerySwiftSyntax.render(source, dark: dark)
        variants[dark] = result
        return result
    }
}

// Lightweight display highlighting for complete examples; copied source stays unchanged.
enum GallerySwiftSyntax {
    private static let tokens = try! NSRegularExpression(pattern:
        #"//[^\n]*|"(?:\\.|[^"\\])*"|\b(?:import|struct|class|enum|var|let|private|public|static|func|if|else|return|some|case|switch|true|false|nil|in)\b|@[A-Za-z]+|\b(?:CN[A-Za-z0-9_]+|View|Text|VStack|HStack|Spacer|Image|Binding|String|Int|Bool)\b"#)

    @MainActor static func highlight(_ source: String, dark: Bool) -> AttributedString {
        GalleryCodeDocument.cached(source).highlighted(dark: dark)
    }

    fileprivate static func render(_ source: String, dark: Bool) -> AttributedString {
        var result = AttributedString(source)
        for match in tokens.matches(in: source, range: NSRange(source.startIndex..., in: source)) {
            guard let stringRange = Range(match.range, in: source),
                  let range = Range(stringRange, in: result) else { continue }
            let token = source[stringRange]
            if token.hasPrefix("//") { result[range].foregroundColor = .secondary }
            else if token.hasPrefix("\"") { result[range].foregroundColor = dark ? Color(red: 1, green: 0.65, blue: 0.55) : Color(red: 0.65, green: 0.22, blue: 0.18) }
            else if token.first?.isUppercase == true { result[range].foregroundColor = dark ? Color(red: 0.48, green: 0.8, blue: 0.83) : Color(red: 0.12, green: 0.43, blue: 0.47) }
            else { result[range].foregroundColor = dark ? Color(red: 0.88, green: 0.6, blue: 0.95) : Color(red: 0.58, green: 0.22, blue: 0.65) }
        }
        return result
    }
}
