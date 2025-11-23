//
//  StatusBarView.swift
//  HexEditor
//
//  Status bar showing file and selection information
//

import SwiftUI

struct StatusBarView: View {
    @ObservedObject var document: HexDocument
    @Binding var selection: Set<Int>
    var isOverwriteMode: Bool
    @Binding var hexInputMode: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            // File size
            HStack(spacing: 4) {
                Image(systemName: "doc.text")
                    .font(.caption)
                Text(formatFileSize(document.buffer.count))
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            
            Divider()
                .frame(height: 12)
            
            // Current offset
            if let offset = selection.min() {
                HStack(spacing: 4) {
                    Image(systemName: "location")
                        .font(.caption)
                    Text("Offset: 0x\(String(format: "%X", offset)) (\(offset))")
                        .font(.caption.monospaced())
                }
                .foregroundColor(.secondary)
            }
            
            // Selection info
            if selection.count > 1 {
                Divider()
                    .frame(height: 12)
                
                HStack(spacing: 4) {
                    Image(systemName: "selection.pin.in.out")
                        .font(.caption)
                    Text("Selected: \(selection.count) bytes")
                        .font(.caption)
                    
                    if let min = selection.min(), let max = selection.max() {
                        Text("(0x\(String(format: "%X", min))-0x\(String(format: "%X", max)))")
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Edit mode indicator
            HStack(spacing: 4) {
                Image(systemName: isOverwriteMode ? "pencil.slash" : "pencil")
                    .font(.caption)
                Text(isOverwriteMode ? "OVR" : "INS")
                    .font(.caption.bold())
            }
            .foregroundColor(isOverwriteMode ? .orange : .blue)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isOverwriteMode ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1))
            )
            
            // Hex input mode indicator
            if hexInputMode {
                HStack(spacing: 4) {
                    Image(systemName: "number")
                        .font(.caption)
                    Text("HEX")
                        .font(.caption.bold())
                }
                .foregroundColor(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green.opacity(0.1))
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
