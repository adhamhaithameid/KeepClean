import SwiftUI

@main
struct KeepCleanApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = AppEnvironment.makeViewModel()

    var body: some Scene {
        WindowGroup {
            RootTabsView(model: model)
                .onAppear {
                    appDelegate.onWillTerminate = {
                        model.handleAppTermination()
                    }
                }
        }
        .defaultSize(width: 760, height: 560)
    }
}
