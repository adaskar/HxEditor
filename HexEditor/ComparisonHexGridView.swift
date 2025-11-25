import SwiftUI
import Combine

struct ComparisonHexGridView: NSViewRepresentable {
    @ObservedObject var document: HexDocument
    var diffResult: EnhancedDiffResult?
    var isLeftSide: Bool
    @Binding var scrollTarget: ComparisonContentView.ScrollTarget?
    @Binding var currentVisibleOffset: Int
    var showOnlyDifferences: Bool
    var currentBlockIndex: Int
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = NSColor(named: "BackgroundColor") ?? .textBackgroundColor
        
        let textView = ComparisonHexTextView()
        textView.hexDocument = document
        textView.diffResult = diffResult
        textView.isLeftSide = isLeftSide
        textView.showOnlyDifferences = showOnlyDifferences
        
        scrollView.documentView = textView
        
        // Observe scrolling to update currentVisibleOffset
        NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: scrollView.contentView,
            queue: .main
        ) { _ in
            context.coordinator.updateVisibleOffset(scrollView)
        }
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? ComparisonHexTextView else { return }
        
        // Update properties
        if textView.hexDocument !== document {
            textView.hexDocument = document
        }
        
        // Check if diff result changed (simple check)
        // In a real app we might want deeper equality or just always update if struct changes
        // Since EnhancedDiffResult is a struct, we can just assign it
        textView.diffResult = diffResult
        textView.isLeftSide = isLeftSide
        textView.showOnlyDifferences = showOnlyDifferences
        
        // Handle programmatic scrolling
        if let target = scrollTarget, target.id != context.coordinator.lastScrollTargetId {
            context.coordinator.lastScrollTargetId = target.id
            scrollToOffset(scrollView, offset: target.offset)
        }
    }
    
    private func scrollToOffset(_ scrollView: NSScrollView, offset: Int) {
        guard let textView = scrollView.documentView as? ComparisonHexTextView else { return }
        
        // Calculate Y position
        // This is tricky with "Show Only Differences" because offsets are not linear
        // We need a method on textView to get Y for offset
        
        // For now, let's assume linear if not filtering, or approximate?
        // Actually, ComparisonHexTextView needs a method `yForOffset(_:)`
        // But we can't easily add it to the NSView from here without casting and ensuring it exists.
        // Let's add `yForOffset` to ComparisonHexTextView in a separate step or just calculate here if possible.
        // But `visibleRows` is private.
        
        // Better approach: Pass the scroll request to the view or coordinator?
        // Let's implement `scrollToOffset` on `ComparisonHexTextView`?
        // No, `NSView` doesn't have that.
        // Let's just calculate linear for now as a fallback, or better:
        // Add a public method to `ComparisonHexTextView` to get rect for offset.
        
        if let y = textView.yPosition(for: offset) {
            let rect = NSRect(x: 0, y: y, width: scrollView.bounds.width, height: 20)
            scrollView.contentView.scrollToVisible(rect)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: ComparisonHexGridView
        var lastScrollTargetId: UUID?
        
        init(_ parent: ComparisonHexGridView) {
            self.parent = parent
        }
        
        func updateVisibleOffset(_ scrollView: NSScrollView) {
            guard let textView = scrollView.documentView as? ComparisonHexTextView else { return }
            let visibleRect = scrollView.documentVisibleRect
            let y = visibleRect.minY
            
            if let offset = textView.offset(at: y) {
                DispatchQueue.main.async {
                    // Only update if significantly different to avoid loop?
                    // Or just update.
                    self.parent.currentVisibleOffset = offset
                }
            }
        }
    }
}
