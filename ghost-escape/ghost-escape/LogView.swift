import SwiftUI

/// Terminal-style view streaming the exploit log in real time.
/// Stays on screen after a failure so the last printed lines remain
/// readable (they pinpoint which kernel step failed).
struct LogView: View {
    @ObservedObject var exploit: ExploitManager
    @ObservedObject private var log = LogManager.shared

    private let background = Color(red: 0.06, green: 0.07, blue: 0.09)
    private let bar = Color(red: 0.09, green: 0.10, blue: 0.13)

    var body: some View {
        VStack(spacing: 0) {
            header
            logScroller
        }
        .background(background.ignoresSafeArea())
    }

    private var header: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(exploit.isRunning ? Color.green : Color.gray)
                .frame(width: 9, height: 9)
            Text("ghost-escape log")
                .font(.headline)
            Spacer()
            if case .failed = exploit.status {
                Button("Done") {
                    exploit.reset()
                }
                .font(.subheadline)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(bar)
    }

    private var logScroller: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(log.logs.enumerated()), id: \.offset) { index, line in
                        Text(line)
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(color(for: line))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(index)
                    }
                }
                .padding(10)
            }
            .onChange(of: log.logs.count) { _ in
                guard !log.logs.isEmpty else { return }
                proxy.scrollTo(log.logs.count - 1, anchor: .bottom)
            }
        }
    }

    private func color(for line: String) -> Color {
        if line.contains("[err]") {
            return Color(red: 1.00, green: 0.45, blue: 0.42)
        }
        if line.contains("[debug]") {
            return Color(red: 0.55, green: 0.60, blue: 0.68)
        }
        return Color(red: 0.78, green: 0.84, blue: 0.88)
    }
}
