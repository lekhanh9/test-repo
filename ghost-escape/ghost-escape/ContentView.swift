import SwiftUI

struct ContentView: View {
    @StateObject private var exploit = ExploitManager.shared

    var body: some View {
        Group {
            if exploit.isEscaped {
                NavigationStack {
                    FileBrowserView(path: "/var/mobile")
                }
            } else {
                runView
            }
        }
        .preferredColorScheme(.dark)
    }

    private var runView: some View {
        VStack(spacing: 24) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("ghost-escape")
                .font(.largeTitle.bold())
            Text(exploit.statusText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                exploit.runExploit()
            } label: {
                HStack(spacing: 8) {
                    if exploit.isRunning {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(exploit.isRunning ? "Running…" : "Run Sandbox Escape")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(exploit.isRunning)
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding(.top, 80)
    }
}
