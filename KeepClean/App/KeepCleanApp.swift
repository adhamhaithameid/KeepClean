@preconcurrency import ApplicationServices
import SwiftUI

@main
struct KeepCleanApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppEnvironment.makeViewModel()

    var body: some Scene {
        WindowGroup {
            ContentGateView(model: model)
                .frame(width: 520, height: 520)
                .onAppear {
                    appDelegate.onWillTerminate = { model.handleAppTermination() }
                    appDelegate.onSleep = { model.handleMacSleep() }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

// MARK: - Content Gate

/// Permission check is ADDITIVE only on launch — we only re-show the setup screen
/// if `setupCompleted` was never saved (first run), NOT if an API transiently
/// returns false due to the TCC race condition at launch.
///
/// The key insight: once `setupCompleted` is stored in UserDefaults we TRUST it
/// on launch. We re-evaluate only when the user is actively on-screen (via polling)
/// or when the permission monitoring detects a real revocation mid-session.
private struct ContentGateView: View {
    @ObservedObject var model: AppViewModel
    @State private var showRevokedInterstitial = false

    var body: some View {
        Group {
            if model.settings.setupCompleted {
                RootTabsView(model: model)
                    .modifier(
                        PermissionChangeModifier(
                            hasAccessibility: model.hasAccessibility,
                            hasInputMonitoring: model.hasInputMonitoring,
                            onDrop: { dropped in
                                if dropped {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        showRevokedInterstitial = true
                                    }
                                }
                            }
                        )
                    )
                    .sheet(isPresented: $showRevokedInterstitial) {
                        PermissionRevokedInterstitialView {
                            showRevokedInterstitial = false
                            model.settings.setupCompleted = false
                        }
                    }
            } else {
                SetupGateView(model: model)
            }
        }
        .onAppear {
            // BUG FIX: Only check permissions on FIRST launch (setupCompleted == false).
            // Once the user has completed setup and we've stored setupCompleted=true,
            // we trust that value. We do NOT re-check at launch because:
            //   1. CGEvent tap creation fails transiently for ~0.5-1s after launch
            //      due to a TCC daemon race condition on ad-hoc signed builds.
            //   2. AXIsProcessTrusted() can also return false during the first runloop tick.
            // Permission state is continuously monitored via the polling task that's
            // started when the user opens Settings or encounters a permission error.
            // The PermissionChangeModifier handles mid-session revocations.
        }
    }
}

private struct SetupGateView: View {
    @ObservedObject var model: AppViewModel
    @StateObject private var setupModel: PermissionSetupViewModel

    init(model: AppViewModel) {
        self.model = model
        _setupModel = StateObject(wrappedValue: PermissionSetupViewModel(settings: model.settings))
    }

    var body: some View {
        PermissionSetupView(model: setupModel)
            .onChange(of: model.settings.setupCompleted) { completed in
                if completed { model.handleInitialAppearance() }
            }
    }
}

// MARK: - Permission Change Monitor (mid-session only)

/// Only fires when the user is already past the setup screen and actively using the app.
/// Uses a timed delay to absorb the TCC daemon propagation lag (~1s).
private struct PermissionChangeModifier: ViewModifier {
    let hasAccessibility: Bool
    let hasInputMonitoring: Bool
    let onDrop: (Bool) -> Void

    @State private var dropDebounce: Task<Void, Never>?

    func body(content: Content) -> some View {
        if #available(macOS 14.0, *) {
            content
                .onChange(of: hasAccessibility) { _, v in debounce(!v) }
                .onChange(of: hasInputMonitoring) { _, v in debounce(!v) }
        } else {
            content
                .onChange(of: hasAccessibility) { v in debounce(!v) }
                .onChange(of: hasInputMonitoring) { v in debounce(!v) }
        }
    }

    /// Waits 1.5 s before treating a `false` reading as a real revocation.
    /// This absorbs TCC daemon lag without affecting real revocations (which stay false).
    private func debounce(_ dropped: Bool) {
        guard dropped else {
            onDrop(false)
            return
        }
        dropDebounce?.cancel()
        dropDebounce = Task {
            try? await Task.sleep(for: .milliseconds(1500))
            guard !Task.isCancelled else { return }
            await MainActor.run { onDrop(true) }
        }
    }
}
