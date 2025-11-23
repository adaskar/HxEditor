import Foundation

struct DiffResult {
    let differentIndices: Set<Int>
    let onlyInFirst: Set<Int> // Indices present in first but not second (if size differs)
    let onlyInSecond: Set<Int> // Indices present in second but not first
}

class DiffEngine {
    static func compare(buffer1: GapBuffer, buffer2: GapBuffer) async -> DiffResult {
        var differences = Set<Int>()
        var onlyInFirst = Set<Int>()
        var onlyInSecond = Set<Int>()
        
        let count1 = buffer1.count
        let count2 = buffer2.count
        let minCount = min(count1, count2)
        
        // Compare overlapping region
        // For large files, we should chunk this.
        // Accessing GapBuffer by index in a loop is O(1) but has overhead.
        // Converting to Data might be faster for comparison if memory allows.
        
        // Let's try direct access first, it's simpler.
        // We can optimize by grabbing chunks if needed.
        
        // Run in background
        await Task.yield()
        
        for i in 0..<minCount {
            if buffer1[i] != buffer2[i] {
                differences.insert(i)
            }
            
            // Yield occasionally to keep UI responsive if this runs on main actor (though it shouldn't)
            if i % 10000 == 0 {
                await Task.yield()
            }
        }
        
        // Handle size differences
        if count1 > count2 {
            for i in count2..<count1 {
                onlyInFirst.insert(i)
            }
        } else if count2 > count1 {
            for i in count1..<count2 {
                onlyInSecond.insert(i)
            }
        }
        
        return DiffResult(differentIndices: differences, onlyInFirst: onlyInFirst, onlyInSecond: onlyInSecond)
    }
}
