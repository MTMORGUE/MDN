// DynamicCheckbox.swift
import SwiftUI

struct DynamicCheckbox: View {
    @Binding var isChecked: Bool
    @Binding var label: String

    var body: some View {
        HStack {
            Button(action: {
                isChecked.toggle()
            }) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .foregroundColor(isChecked ? .blue : .gray)
                    .imageScale(.large)
            }
            TextField("Task", text: $label)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.vertical, 5)
    }
}
