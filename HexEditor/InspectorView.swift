import SwiftUI

struct InspectorView: View {
    @ObservedObject var document: HexDocument
    @Binding var selection: Set<Int>
    @State private var isLittleEndian: Bool = true
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Inspector")
                .font(.headline)
                .padding(.bottom)
            
            Toggle("Little Endian", isOn: $isLittleEndian)
                .padding(.bottom)
            
            if let index = selection.min(), index < document.buffer.count {
                inspectorRow(title: "8-bit Signed", value: getValue(at: index, type: Int8.self))
                inspectorRow(title: "8-bit Unsigned", value: getValue(at: index, type: UInt8.self))
                
                Divider()
                
                inspectorRow(title: "16-bit Signed", value: getValue(at: index, type: Int16.self))
                inspectorRow(title: "16-bit Unsigned", value: getValue(at: index, type: UInt16.self))
                
                Divider()
                
                inspectorRow(title: "32-bit Signed", value: getValue(at: index, type: Int32.self))
                inspectorRow(title: "32-bit Unsigned", value: getValue(at: index, type: UInt32.self))
                
                Divider()
                
                inspectorRow(title: "Float", value: getValue(at: index, type: Float32.self))
                inspectorRow(title: "Double", value: getValue(at: index, type: Float64.self))
            } else {
                Text("No selection")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 200, maxWidth: 300)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func inspectorRow(title: String, value: String) -> some View {
        Group {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.monospaced(.body)())
                .textSelection(.enabled)
        }
    }
    
    private func getValue<T: Numeric & CustomStringConvertible>(at index: Int, type: T.Type) -> String {
        let size = MemoryLayout<T>.size
        guard index + size <= document.buffer.count else { return "N/A" }
        
        var bytes: [UInt8] = []
        for i in 0..<size {
            bytes.append(document.buffer[index + i])
        }
        
        // Handle endianness manually since we are constructing from bytes
        if isLittleEndian {
            // Little endian is default for intel/arm, so just load
             return bytes.withUnsafeBytes { $0.load(as: T.self) }.description
        } else {
            // Big endian: reverse bytes then load
            return Array(bytes.reversed()).withUnsafeBytes { $0.load(as: T.self) }.description
        }
    }
}
