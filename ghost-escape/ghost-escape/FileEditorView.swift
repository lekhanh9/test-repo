import SwiftUI

/// Reads, edits and saves the content of a text-ish file.
struct FileEditorView: View {
    let filePath: String
    let fileName: String

    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var original = ""
    @State private var errorMessage: String?
    @State private var isLoading = true

    private static let maxFileSize: Int64 = 8 * 1024 * 1024  // 8 MB

    static let editableExtensions: Set<String> = [
        "txt", "plist", "strings", "xml", "json", "log", "ini", "conf",
        "sh", "md", "c", "h", "m", "mm", "swift", "yml", "yaml", "list",
        "csv", "html", "css", "js", "entitlements", "mobileconfig",
    ]

    static func isEditable(_ name: String) -> Bool {
        editableExtensions.contains((name as NSString).pathExtension.lowercased())
    }

    var body: some View {
        VStack(spacing: 0) {
            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemRed).opacity(0.15))
            }
            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .navigationTitle(fileName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(isLoading || text == original)
            }
        }
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        let path = filePath
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let attrs = try FileManager.default.attributesOfItem(atPath: path)
                let size = (attrs[.size] as? NSNumber)?.int64Value ?? 0
                guard size <= Self.maxFileSize else {
                    throw CocoaError(.fileReadTooLarge)
                }
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                guard let decoded = String(data: data, encoding: .utf8)
                        ?? String(data: data, encoding: .isoLatin1) else {
                    throw CocoaError(.fileReadInapplicableStringEncoding)
                }
                DispatchQueue.main.async {
                    self.text = decoded
                    self.original = decoded
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    private func save() {
        let path = filePath
        let content = text
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try content.write(toFile: path, atomically: true, encoding: .utf8)
                DispatchQueue.main.async {
                    self.original = content  // re-enables Save only on further edits
                    self.errorMessage = nil
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
