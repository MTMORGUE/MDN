import SwiftUI

class ThemeManager: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode: Bool = false {
        didSet {
            objectWillChange.send()
        }
    }

    func toggleDarkMode() {
        isDarkMode.toggle()
    }
}
