import SwiftUI

@main
struct NestMindApp: App {
  @State private var appModel = AppModel()

  var body: some Scene {
    WindowGroup {
      AppRootView()
        .environment(appModel)
        .task {
          appModel.start()
        }
    }
  }
}

