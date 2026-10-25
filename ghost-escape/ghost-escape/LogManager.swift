import Combine
import Foundation

/// In-memory store for the exploit log, observed by LogView.
/// Every append happens on the main queue, so @Published updates are
/// always main-thread safe.
final class LogManager: ObservableObject {
    static let shared = LogManager()

    @Published private(set) var logs: [String] = []

    private let timestampFormatter: DateFormatter

    private init() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        timestampFormatter = formatter
    }

    func append(_ message: String) {
        logs.append("\(timestampFormatter.string(from: Date()))  \(message)")
    }

    func clear() {
        logs.removeAll()
    }
}

/// C bridge for the exploit: common.h routes every LOG/LOG_ERR/LOG_DEBUG
/// macro through this symbol, from any thread. The Swift-side name is
/// swift_log_bridge to avoid clashing with the imported C declaration;
/// @_cdecl emits the `swift_log` symbol the C code links against.
@_cdecl("swift_log")
func swift_log_bridge(_ message: UnsafePointer<CChar>?) {
    guard let message else { return }
    let text = String(cString: message)
    DispatchQueue.main.async {
        LogManager.shared.append(text)
    }
}
