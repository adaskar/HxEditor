import Foundation

/// A Gap Buffer implementation for efficient editing of data.
/// It maintains a "gap" in the storage to allow for O(1) insertions and deletions at the cursor position.
struct GapBuffer: RandomAccessCollection {
    typealias Index = Int
    typealias Element = UInt8
    
    private var buffer: [UInt8]
    private var gapStart: Int
    private var gapEnd: Int
    
    init(data: Data = Data()) {
        self.buffer = [UInt8](data)
        self.gapStart = buffer.count
        self.gapEnd = buffer.count
    }
    
    var startIndex: Int { 0 }
    var endIndex: Int { buffer.count - (gapEnd - gapStart) }
    
    /// The total number of bytes in the buffer (excluding the gap).
    var count: Int {
        return endIndex
    }
    
    /// Accesses the byte at the given index.
    subscript(index: Int) -> UInt8 {
        get {
            let physicalIndex = index < gapStart ? index : index + (gapEnd - gapStart)
            return buffer[physicalIndex]
        }
        set {
            let physicalIndex = index < gapStart ? index : index + (gapEnd - gapStart)
            buffer[physicalIndex] = newValue
        }
    }
    
    /// Moves the gap to the specified index.
    mutating func moveGap(to index: Int) {
        if index == gapStart { return }
        
        let gapSize = gapEnd - gapStart
        
        if index < gapStart {
            // Move gap left
            buffer.replaceSubrange(index + gapSize..<gapStart + gapSize, with: buffer[index..<gapStart])
            gapStart = index
            gapEnd = gapStart + gapSize
        } else {
            // Move gap right
            let moveCount = index - gapStart
            buffer.replaceSubrange(gapStart..<gapStart + moveCount, with: buffer[gapEnd..<gapEnd + moveCount])
            gapStart += moveCount
            gapEnd += moveCount
        }
    }
    
    /// Inserts a byte at the current gap position.
    mutating func insert(_ byte: UInt8, at index: Int) {
        moveGap(to: index)
        
        if gapStart == gapEnd {
            expandGap()
        }
        
        buffer[gapStart] = byte
        gapStart += 1
    }
    
    /// Inserts a sequence of bytes at the current gap position.
    mutating func insert<S: Sequence>(_ bytes: S, at index: Int) where S.Element == UInt8 {
        moveGap(to: index)
        
        for byte in bytes {
            if gapStart == gapEnd {
                expandGap()
            }
            buffer[gapStart] = byte
            gapStart += 1
        }
    }
    
    /// Deletes a byte at the specified index.
    mutating func delete(at index: Int) {
        moveGap(to: index + 1)
        if gapStart > 0 {
            gapStart -= 1
        }
    }
    
    /// Deletes a range of bytes.
    mutating func delete(in range: Range<Int>) {
        moveGap(to: range.upperBound)
        gapStart -= range.count
    }
    
    /// Expands the gap when it's full.
    private mutating func expandGap() {
        let newCapacity = Swift.max(buffer.count * 2, 64)
        let gapSize = newCapacity - buffer.count
        
        // Insert gap at current gapEnd
        // Actually, since we are using Array, we can just insert uninitialized space or zeros
        // But Array doesn't support uninitialized insert easily without unsafe.
        // For simplicity in Swift, we'll just insert zeros.
        // Optimization: Use UnsafeMutableBufferPointer for better performance later.
        let zeros = [UInt8](repeating: 0, count: gapSize)
        buffer.insert(contentsOf: zeros, at: gapEnd)
        gapEnd += gapSize
    }
    
    /// Returns the data as a contiguous Data object.
    func toData() -> Data {
        var data = Data()
        data.append(contentsOf: buffer[0..<gapStart])
        data.append(contentsOf: buffer[gapEnd..<buffer.count])
        return data
    }
}
