// DynamicTableView.swift
import SwiftUI

struct DynamicTableView: View {
    @Binding var tableData: [[String]]

    var body: some View {
        VStack {
            ForEach(tableData.indices, id: \.self) { rowIndex in
                HStack {
                    ForEach(tableData[rowIndex].indices, id: \.self) { colIndex in
                        TextField(
                            "Cell",
                            text: Binding(
                                get: { tableData[rowIndex][colIndex] },
                                set: { tableData[rowIndex][colIndex] = $0 }
                            )
                        )
                        .frame(maxWidth: .infinity)
                        .padding(5)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(5)
                    }
                }
            }
            HStack {
                Button(action: {
                    tableData.append(Array(repeating: "", count: tableData.first?.count ?? 2))
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add Row")
                    }
                }
                Spacer()
                Button(action: {
                    for rowIndex in tableData.indices {
                        tableData[rowIndex].append("")
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add Column")
                    }
                }
            }
            .padding(.top, 5)
        }
    }
}
