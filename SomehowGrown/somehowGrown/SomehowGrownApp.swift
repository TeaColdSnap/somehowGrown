import SwiftUI

@main
struct SomehowGrownApp: App {

    init() {
        let brandColor = UIColor(red: 163/255, green: 129/255, blue: 83/255, alpha: 1)
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: brandColor]
        UINavigationBar.appearance().titleTextAttributes      = [.foregroundColor: brandColor]
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
