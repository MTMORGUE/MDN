import SwiftUI

struct AppearanceView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        Form {
            Toggle("Dark Mode", isOn: $isDarkMode)
        }
        .navigationTitle("Appearance")
    }
}
