import SwiftUI

struct SearchView: View {
    @ObservedObject var document: HexDocument
    @Binding var selection: Set<Int>
    @Binding var isPresented: Bool
    @State private var searchString: String = ""
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var searchMode: SearchMode = .text
    @State private var caseSensitive = false
    
    enum SearchMode: String, CaseIterable {
        case text = "Text"
        case hex = "Hex"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Find")
                .font(.title2.bold())
            
            // Search mode picker
            Picker("Search Mode", selection: $searchMode) {
                ForEach(SearchMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 300)
            
            // Search field
            VStack(alignment: .leading, spacing: 4) {
                TextField(searchMode == .hex ? "Hex (e.g., 48656C6C6F or 48 65 6C 6C 6F)" : "Search text", 
                         text: $searchString)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 400)
                    .onSubmit {
                        performSearch()
                    }
                
                if searchMode == .hex {
                    Text("Enter hex values without 0x prefix")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Options
            if searchMode == .text {
                Toggle("Case Sensitive", isOn: $caseSensitive)
                    .frame(width: 300)
            }
            
            if isSearching {
                ProgressView()
                    .scaleEffect(0.5)
            }
            
            if let error = searchError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 12) {
                Button("Close") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Find Next") {
                    performSearch()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 500, height: 300)
    }
    
    private func performSearch() {
        guard !searchString.isEmpty else { return }
        isSearching = true
        searchError = nil
        
        let query = searchString
        let startIndex = (selection.max() ?? -1) + 1
        
        // Run in background
        Task {
            let searchBytes: [UInt8]?
            
            if searchMode == .hex {
                // Parse hex input
                searchBytes = HexInputHelper.hexStringToBytes(query)
                if searchBytes == nil {
                    await MainActor.run {
                        searchError = "Invalid hex format. Use format: 48656C6C6F or 48 65 6C 6C 6F"
                        isSearching = false
                    }
                    return
                }
            } else {
                // Text search
                if caseSensitive {
                    searchBytes = [UInt8](query.data(using: .utf8) ?? Data())
                } else {
                    searchBytes = [UInt8](query.lowercased().data(using: .utf8) ?? Data())
                }
            }
            
            // Safely unwrap searchBytes
            guard let bytes = searchBytes, !bytes.isEmpty else {
                await MainActor.run {
                    searchError = "Invalid search query"
                    isSearching = false
                }
                return
            }
            
            if let index = await find(bytes: bytes, start: startIndex) {
                await MainActor.run {
                    // Select all matched bytes
                    let range = index..<(index + bytes.count)
                    selection = Set(range)
                    isSearching = false
                }
            } else {
                await MainActor.run {
                    searchError = "Not found"
                    isSearching = false
                }
            }
        }
    }
    
    private func find(bytes searchBytes: [UInt8], start: Int) async -> Int? {
        guard !searchBytes.isEmpty else { return nil }
        
        let buffer = document.buffer
        let count = buffer.count
        let searchCount = searchBytes.count
        
        if start >= count { return nil }
        
        // For case-insensitive text search
        let shouldLowercase = searchMode == .text && !caseSensitive
        
        // Linear search
        for i in start..<(count - searchCount + 1) {
            var match = true
            for j in 0..<searchCount {
                let bufferByte = buffer[i + j]
                let searchByte = searchBytes[j]
                
                if shouldLowercase {
                    // Compare as lowercase ASCII
                    let bufferLower = (bufferByte >= 65 && bufferByte <= 90) ? bufferByte + 32 : bufferByte
                    if bufferLower != searchByte {
                        match = false
                        break
                    }
                } else {
                    if bufferByte != searchByte {
                        match = false
                        break
                    }
                }
            }
            
            if match {
                return i
            }
            
            // Yield to allow UI updates if long search
            if i % 10000 == 0 {
                await Task.yield()
            }
        }
        
        return nil
    }
}
