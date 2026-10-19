import SwiftUI
import SwiftData

@main
struct SmartPOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.layoutDirection, .rightToLeft)
                .environment(\.locale, Locale(identifier: "ar"))
        }
        .modelContainer(for: [Product.self, SaleTransaction.self, SaleItem.self])
    }
}
