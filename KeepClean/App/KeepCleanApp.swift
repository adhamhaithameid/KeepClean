@preconcurrency import ApplicationServices
import SwiftUI

@main
struct KeepCleanApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppEnvironment.makeViewModel()

    var body: some Scene {
        WindowGroup {
            ContentGateView(model: model)
                .onAppear {
                    appDelegate.onWillTerminate = {
                        model.handleAppTermination()
                    }
                }
        }
        .defaultSize(width: 580, height: 420)
    }
}

/// Shows the permission setup screen until both permissions are granted,
/// then transitions to the main app UI.
private struct ContentGateView: View {
    @ObservedObject var model: AppViewModel
    @StateObject private var setupModel: PermissionSetupViewModel

    init(model: AppViewModel) {
        self.model = model
        _setupModel = StateObject(wrappedValue: PermissionSetupViewModel(settings: model.settings))
    }

    var body: some View {
        Group {
            if model.settings.setupCompleted {
                RootTabsView(model: model)
            } else {
                PermissionSetupView(model: setupModel)
                    .onChange(of: model.settings.setupCompleted) { completed in
                        if completed {
                            model.handleInitialAppearance()
                        }
                    }
            }
        }
        .onAppear {
            resetSetupIfPermissionsRevoked()
        }
    }

    private func resetSetupIfPermissionsRevoked() {
        guard model.settings.setupCompleted else { return }
        let hasAccessibility = AXIsProcessTrusted()
        let hasInputMonitoring = CGPreflightListenEventAccess()
        if !hasAccessibility || !hasInputMonitoring {
            model.settings.setupCompleted = false
        }
    }
}
