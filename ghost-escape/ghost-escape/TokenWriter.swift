import Foundation

/// App A -> App B glue: persists the kernel-signed sandbox extension token
/// into the shared App Group container, twice for redundancy.
///
/// PrivilegedFilza (App B) reads it back via UserDefaults(suiteName:) first,
/// then falls back to the raw file — the file is the authoritative copy.
enum TokenWriter {
    static let appGroupID = "group.com.kurishu.ghost"
    static let defaultsKey = "sandbox_extension_token"
    static let fileName = "sbx_token.txt"

    /// Writes `token` to the App Group UserDefaults AND to sbx_token.txt,
    /// then verifies the file round-trip. Returns true when the file copy
    /// reads back byte-identical.
    @discardableResult
    static func persist(token: String) -> Bool {
        guard !token.isEmpty else {
            swift_log("[err] TokenWriter: refusing to persist empty token")
            return false
        }

        // 1) UserDefaults(suiteName:) — convenient but less reliable across
        //    processes (sync timing), so it is only the secondary channel.
        let defaults = UserDefaults(suiteName: appGroupID)
        defaults?.set(token, forKey: defaultsKey)
        let defaultsOK = defaults?.synchronize() ?? false

        // 2) Plain file in the group container — the authoritative copy.
        guard let container = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            swift_log("[err] TokenWriter: no container for \(appGroupID) — missing application-groups entitlement")
            return false
        }

        let url = container.appendingPathComponent(fileName)
        var fileOK = false
        do {
            try token.write(to: url, atomically: true, encoding: .utf8)
            let readback = try String(contentsOf: url, encoding: .utf8)
            fileOK = readback.trimmingCharacters(in: .whitespacesAndNewlines) == token
        } catch {
            swift_log("[err] TokenWriter: file write/verify failed: \(error.localizedDescription)")
        }

        swift_log("TokenWriter: defaults \(defaultsOK ? "synced" : "not synced"), file \(fileOK ? "verified" : "FAILED")")
        return fileOK
    }
}
