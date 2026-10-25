import SwiftUI

struct FileEntry: Identifiable {
    let id: String  // full path
    let name: String
    let isDirectory: Bool
    let size: Int64
}

struct FileBrowserView: View {
    @State private var currentPath: String
    @State private var entries: [FileEntry] = []
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var editorFile: FileEntry?

    init(path: String = "/var/mobile") {
        _currentPath = State(initialValue: path)
    }

    var body: some View {
        VStack(spacing: 0) {
            breadcrumb
            Divider()
            content
        }
        .navigationTitle("Files")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    goUp()
                } label: {
                    Label("Up", systemImage: "arrow.up")
                }
                .disabled(currentPath == "/")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    load()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .sheet(item: $editorFile) { file in
            NavigationStack {
                FileEditorView(filePath: file.id, fileName: file.name)
            }
        }
        .onAppear(perform: load)
    }

    // MARK: - Breadcrumb

    private var pathComponents: [String] {
        currentPath.split(separator: "/").map(String.init)
    }

    private var breadcrumb: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                Button {
                    navigate(to: "/")
                } label: {
                    Image(systemName: "house.fill")
                }
                ForEach(Array(pathComponents.enumerated()), id: \.offset) { index, component in
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Button(component) {
                        let prefix = pathComponents[0...index].joined(separator: "/")
                        navigate(to: "/" + prefix)
                    }
                    .font(.footnote)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Content

    private var content: some View {
        List {
            if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            if entries.isEmpty && !isLoading {
                Text("Empty folder")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ForEach(entries) { entry in
                row(for: entry)
            }
        }
        .listStyle(.plain)
        .refreshable { load() }
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
    }

    private func row(for entry: FileEntry) -> some View {
        Button {
            open(entry)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: entry.isDirectory ? "folder.fill" : "doc")
                    .foregroundStyle(entry.isDirectory ? .yellow : .secondary)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.name)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if !entry.isDirectory {
                        Text(ByteCountFormatter.string(fromByteCount: entry.size, countStyle: .file))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if entry.isDirectory {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func open(_ entry: FileEntry) {
        if entry.isDirectory {
            navigate(to: entry.id)
        } else if FileEditorView.isEditable(entry.name) {
            editorFile = entry
        } else {
            errorMessage = "Cannot preview \(entry.name)"
        }
    }

    private func navigate(to path: String) {
        currentPath = path
        load()
    }

    private func goUp() {
        guard currentPath != "/" else { return }
        let parent = (currentPath as NSString).deletingLastPathComponent
        navigate(to: parent.isEmpty ? "/" : parent)
    }

    private func load() {
        isLoading = true
        errorMessage = nil
        let path = currentPath
        DispatchQueue.global(qos: .userInitiated).async {
            let result = Self.loadEntries(at: path)
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let loaded):
                    self.entries = loaded
                case .failure(let error):
                    self.entries = []
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    static func loadEntries(at path: String) -> Result<[FileEntry], Error> {
        let fm = FileManager.default
        do {
            let names = try fm.contentsOfDirectory(atPath: path)
            var directories: [FileEntry] = []
            var files: [FileEntry] = []
            for name in names {
                let full = (path as NSString).appendingPathComponent(name)
                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: full, isDirectory: &isDir) else { continue }
                let attrs = try? fm.attributesOfItem(atPath: full)
                let size = (attrs?[.size] as? NSNumber)?.int64Value ?? 0
                let entry = FileEntry(id: full, name: name, isDirectory: isDir.boolValue, size: size)
                if entry.isDirectory {
                    directories.append(entry)
                } else {
                    files.append(entry)
                }
            }
            let byName: (FileEntry, FileEntry) -> Bool = {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            return .success(directories.sorted(by: byName) + files.sorted(by: byName))
        } catch {
            return .failure(error)
        }
    }
}
