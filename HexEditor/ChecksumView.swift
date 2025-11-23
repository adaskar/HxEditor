import SwiftUI
import CryptoKit

struct ChecksumView: View {
    @ObservedObject var document: HexDocument
    @Binding var selection: Set<Int>
    @Binding var isPresented: Bool
    
    @State private var md5Hash: String = "Calculating..."
    @State private var sha1Hash: String = "Calculating..."
    @State private var sha256Hash: String = "Calculating..."
    @State private var useSelection: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Checksums")
                .font(.headline)
            
            Toggle("Calculate for Selection Only", isOn: $useSelection)
                .disabled(selection.isEmpty)
                .onChange(of: useSelection) {
                    calculateChecksums()
                }
            
            Form {
                Section(header: Text("MD5")) {
                    Text(md5Hash)
                        .font(.monospaced(.body)())
                        .textSelection(.enabled)
                }
                
                Section(header: Text("SHA-1")) {
                    Text(sha1Hash)
                        .font(.monospaced(.body)())
                        .textSelection(.enabled)
                }
                
                Section(header: Text("SHA-256")) {
                    Text(sha256Hash)
                        .font(.monospaced(.body)())
                        .textSelection(.enabled)
                }
            }
            
            HStack {
                Spacer()
                Button("Close") {
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 500, height: 400)
        .onAppear {
            if !selection.isEmpty {
                useSelection = true
            }
            calculateChecksums()
        }
    }
    
    private func calculateChecksums() {
        md5Hash = "Calculating..."
        sha1Hash = "Calculating..."
        sha256Hash = "Calculating..."
        
        let dataToHash: Data
        if useSelection && !selection.isEmpty {
            let sortedIndices = selection.sorted()
            let bytes = sortedIndices.map { document.buffer[$0] }
            dataToHash = Data(bytes)
        } else {
            // GapBuffer now conforms to Sequence (via RandomAccessCollection)
            dataToHash = Data(document.buffer)
        }
        
        Task {
            let md5 = Insecure.MD5.hash(data: dataToHash).map { String(format: "%02x", $0) }.joined()
            let sha1 = Insecure.SHA1.hash(data: dataToHash).map { String(format: "%02x", $0) }.joined()
            let sha256 = SHA256.hash(data: dataToHash).map { String(format: "%02x", $0) }.joined()
            
            await MainActor.run {
                self.md5Hash = md5
                self.sha1Hash = sha1
                self.sha256Hash = sha256
            }
        }
    }
}
