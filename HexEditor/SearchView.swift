import SwiftUI

struct SearchView: View {
    @ObservedObject var document: HexDocument
    @Binding var selection: Set<Int>
    @Binding var isPresented: Bool
    @Binding var cursorIndex: Int?
    @Binding var selectionAnchor: Int?
    
    @State private var searchString: String = ""
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var searchMode: SearchMode = .text
    @State private var caseSensitive = false
    @State private var offset = CGSize.zero
    @FocusState private var isFocused: Bool
    
    enum SearchMode: String, CaseIterable {
        case text = "Text"
        case hex = "Hex"
    }
    
    enum SearchDirection {
        case forward
        case backward
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header / Drag Handle
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                Text("Find")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            }
            .padding(.bottom, 4)
            
            // Search Input
            HStack(spacing: 8) {
                TextField(searchMode == .hex ? "Hex Bytes" : "Search Text", text: $searchString)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                    .onSubmit {
                        performSearch(direction: .forward)
                    }
                
                Button(action: { performSearch(direction: .backward) }) {
                    Image(systemName: "arrow.left")
                }
                .disabled(searchString.isEmpty)
                .help("Find Previous")
                
                Button(action: { performSearch(direction: .forward) }) {
                    Image(systemName: "arrow.right")
                }
                .disabled(searchString.isEmpty)
                .keyboardShortcut(.defaultAction)
                .help("Find Next")
            }
            
            // Options
            HStack {
                Picker("", selection: $searchMode) {
                    ForEach(SearchMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
                
                if searchMode == .text {
                    Toggle("Case Sensitive", isOn: $caseSensitive)
                        .toggleStyle(.checkbox)
                        .font(.caption)
                }
                
                Spacer()
            }
            
            // Status / Error
            if isSearching {
                HStack {
                    ProgressView()
                        .scaleEffect(0.5)
                    Text("Searching...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else if let error = searchError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .frame(width: 320)
        .background(Material.regular)
        .cornerRadius(12)
        .shadow(radius: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .offset(offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = CGSize(width: value.translation.width, height: value.translation.height)
                }
                .onEnded { value in
                    offset = CGSize(width: value.translation.width, height: value.translation.height)
                }
        )
        .onAppear {
            isFocused = true
        }
    }
    
    private func performSearch(direction: SearchDirection) {
        guard !searchString.isEmpty else { return }
        isSearching = true
        searchError = nil
        
        let query = searchString
        
        // Calculate start index
        let startIndex: Int
        if direction == .forward {
            startIndex = (selection.max() ?? -1) + 1
        } else {
            startIndex = (selection.min() ?? 0) - 1
        }
        
        // Run in background
        Task {
            let searchBytes: [UInt8]?
            
            if searchMode == .hex {
                // Parse hex input - handle spaces and newlines
                let cleaned = query.components(separatedBy: .whitespacesAndNewlines).joined()
                searchBytes = HexInputHelper.hexStringToBytes(cleaned)
                if searchBytes == nil {
                    await MainActor.run {
                        searchError = "Invalid hex format"
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
            
            let foundIndex: Int?
            if direction == .forward {
                foundIndex = await findForward(bytes: bytes, start: startIndex)
            } else {
                foundIndex = await findBackward(bytes: bytes, start: startIndex)
            }
            
            if let index = foundIndex {
                await MainActor.run {
                    // Select all matched bytes
                    let range = index..<(index + bytes.count)
                    selection = Set(range)
                    // Update cursor to end of selection for L-to-R feel
                    cursorIndex = index + bytes.count - 1
                    selectionAnchor = index
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
    
    private func findForward(bytes searchBytes: [UInt8], start: Int) async -> Int? {
        guard !searchBytes.isEmpty else { return nil }
        
        let buffer = document.buffer
        let count = buffer.count
        let searchCount = searchBytes.count
        
        if start >= count { return nil }
        let effectiveStart = max(0, start)
        
        // For case-insensitive text search
        let shouldLowercase = searchMode == .text && !caseSensitive
        
        // Linear search
        for i in effectiveStart..<(count - searchCount + 1) {
            if checkMatch(at: i, buffer: buffer, searchBytes: searchBytes, shouldLowercase: shouldLowercase) {
                return i
            }
            
            // Yield to allow UI updates if long search
            if i % 5000 == 0 {
                await Task.yield()
            }
        }
        
        return nil
    }
    
    private func findBackward(bytes searchBytes: [UInt8], start: Int) async -> Int? {
        guard !searchBytes.isEmpty else { return nil }
        
        let buffer = document.buffer
        let count = buffer.count
        let searchCount = searchBytes.count
        
        if start < 0 { return nil }
        let effectiveStart = min(start, count - searchCount)
        
        // For case-insensitive text search
        let shouldLowercase = searchMode == .text && !caseSensitive
        
        // Linear search backward
        for i in stride(from: effectiveStart, through: 0, by: -1) {
            if checkMatch(at: i, buffer: buffer, searchBytes: searchBytes, shouldLowercase: shouldLowercase) {
                return i
            }
            
            // Yield to allow UI updates if long search
            if i % 5000 == 0 {
                await Task.yield()
            }
        }
        
        return nil
    }
    
    private func checkMatch(at index: Int, buffer: GapBuffer, searchBytes: [UInt8], shouldLowercase: Bool) -> Bool {
        for j in 0..<searchBytes.count {
            let bufferByte = buffer[index + j]
            let searchByte = searchBytes[j]
            
            if shouldLowercase {
                // Compare as lowercase ASCII
                let bufferLower = (bufferByte >= 65 && bufferByte <= 90) ? bufferByte + 32 : bufferByte
                if bufferLower != searchByte {
                    return false
                }
            } else {
                if bufferByte != searchByte {
                    return false
                }
            }
        }
        return true
    }
}
