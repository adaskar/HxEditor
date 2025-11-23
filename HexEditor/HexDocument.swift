import SwiftUI
import UniformTypeIdentifiers
import Combine

final class HexDocument: ReferenceFileDocument {
    @Published var buffer: GapBuffer
    
    init(initialData: Data = Data()) {
        self.buffer = GapBuffer(data: initialData)
    }

    static var readableContentTypes: [UTType] { [.item] }

    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.buffer = GapBuffer(data: data)
    }
    
    func snapshot(contentType: UTType) throws -> Data {
        return buffer.toData()
    }
    
    func fileWrapper(snapshot: Data, configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: snapshot)
    }
    
    // MARK: - Mutation Methods with Undo Support
    
    func insert(_ byte: UInt8, at index: Int, undoManager: UndoManager? = nil) {
        buffer.insert(byte, at: index)
        
        undoManager?.registerUndo(withTarget: self) { doc in
            doc.delete(at: index, undoManager: undoManager)
        }
    }
    
    func insert(bytes: [UInt8], at index: Int, undoManager: UndoManager? = nil) {
        for (i, byte) in bytes.enumerated() {
            buffer.insert(byte, at: index + i)
        }
        
        undoManager?.registerUndo(withTarget: self) { doc in
            doc.delete(indices: Array(index..<(index + bytes.count)), undoManager: undoManager)
        }
    }
    
    func delete(at index: Int, undoManager: UndoManager? = nil) {
        let byte = buffer[index]
        buffer.delete(at: index)
        
        undoManager?.registerUndo(withTarget: self) { doc in
            doc.insert(byte, at: index, undoManager: undoManager)
        }
    }
    
    func delete(indices: [Int], undoManager: UndoManager? = nil) {
        // Indices must be sorted descending to avoid shifting issues during deletion
        let sortedIndices = indices.sorted(by: >)
        var deletedBytes: [(Int, UInt8)] = []
        
        for index in sortedIndices {
            let byte = buffer[index]
            deletedBytes.append((index, byte))
            buffer.delete(at: index)
        }
        
        undoManager?.registerUndo(withTarget: self) { doc in
            // To undo, we insert back. We need to insert in reverse order of deletion (ascending index)
            // or just insert each one. Since we stored them, we can just iterate.
            // If we deleted 5, then 4. We insert 4, then 5.
            for (index, byte) in deletedBytes.reversed() {
                doc.insert(byte, at: index, undoManager: undoManager)
            }
        }
    }
    
    func replace(at index: Int, with byte: UInt8, undoManager: UndoManager? = nil) {
        let oldByte = buffer[index]
        buffer[index] = byte
        
        undoManager?.registerUndo(withTarget: self) { doc in
            doc.replace(at: index, with: oldByte, undoManager: undoManager)
        }
    }
}
