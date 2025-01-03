import SwiftUI

struct SettingsView: View {
    var onClose: () -> Void

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Settings")
                            .font(.headline)
                            .padding(.leading, 16)
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .padding(.trailing, 16)
                        }
                    }
                    .padding(.top, 8)

                    Divider()

                    // Appearance link
                    NavigationLink(destination: AppearanceView()) {
                        HStack {
                            Image(systemName: "paintbrush")
                                .foregroundColor(.blue)
                            Text("Appearance")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    Spacer()
                }
            }
            .cornerRadius(12)
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
