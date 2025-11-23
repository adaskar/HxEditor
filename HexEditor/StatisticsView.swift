import SwiftUI

struct StatisticsView: View {
    @ObservedObject var document: HexDocument
    @Binding var isPresented: Bool
    
    @State private var byteCounts: [Int] = Array(repeating: 0, count: 256)
    @State private var entropy: Double = 0.0
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 20) {
            Text("File Statistics")
                .font(.headline)
            
            if isLoading {
                ProgressView("Calculating...")
            } else {
                VStack(alignment: .leading) {
                    Text("Entropy: \(String(format: "%.4f", entropy)) bits/byte")
                    
                    Text("Byte Distribution")
                        .font(.subheadline)
                        .padding(.top)
                    
                    GeometryReader { geometry in
                        HStack(alignment: .bottom, spacing: 0) {
                            if let maxCount = byteCounts.max(), maxCount > 0 {
                                ForEach(0..<256) { i in
                                    let height = CGFloat(byteCounts[i]) / CGFloat(maxCount) * geometry.size.height
                                    Rectangle()
                                        .fill(Color.accentColor)
                                        .frame(width: geometry.size.width / 256, height: height)
                                }
                            }
                        }
                    }
                    .frame(height: 200)
                    .background(Color.gray.opacity(0.1))
                    .border(Color.gray.opacity(0.2))
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
        .frame(width: 600, height: 400)
        .onAppear {
            calculateStatistics()
        }
    }
    
    private func calculateStatistics() {
        isLoading = true
        let buffer = document.buffer
        
        Task {
            var counts = Array(repeating: 0, count: 256)
            for byte in buffer {
                counts[Int(byte)] += 1
            }
            
            // Calculate Entropy
            // H = -sum(p_i * log2(p_i))
            var ent: Double = 0.0
            let total = Double(buffer.count)
            if total > 0 {
                for count in counts {
                    if count > 0 {
                        let p = Double(count) / total
                        ent -= p * log2(p)
                    }
                }
            }
            
            await MainActor.run {
                self.byteCounts = counts
                self.entropy = ent
                self.isLoading = false
            }
        }
    }
}
