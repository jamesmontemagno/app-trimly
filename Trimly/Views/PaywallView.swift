import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var storeManager: StoreManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.yellow)
                            .padding()
                            .background(
                                Circle()
                                    .fill(Color.yellow.opacity(0.2))
                            )
                        
                        Text("Unlock TrimTally Pro")
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                        
                        Text("Take your weight tracking to the next level with advanced features.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Features
                    VStack(spacing: 24) {
                        FeatureRow(icon: "heart.fill", title: "HealthKit Sync", description: "Automatically sync your weight data with Apple Health.", color: .pink)
                        FeatureRow(icon: "square.and.arrow.up", title: "Data Export", description: "Export your complete history to CSV for analysis.", color: .blue)
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Advanced Analytics", description: "Gain deeper insights into your progress.", color: .purple)
                    }
                    .padding(.horizontal)
                    
                    // Purchase Button
                    VStack(spacing: 16) {
                        if let product = storeManager.products.first(where: { $0.id == "trimtallypro" }) {
                            ProductView(product) {
                                Image(systemName: "crown.fill")
                            }
                            .productViewStyle(.large)
                            .padding(.horizontal)
                        } else {
                            ProgressView()
                                .padding()
                        }
                        
                        Button("Restore Purchases") {
                            Task {
                                await storeManager.restore()
                            }
                        }
                        .font(.footnote)
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
