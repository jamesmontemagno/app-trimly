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
                            .accessibilityLabel(String(localized: L10n.Paywall.premiumFeatureLabel))
                        
                        Text(L10n.Paywall.title)
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                        
                        Text(L10n.Paywall.subtitle)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Features
                    VStack(spacing: 24) {
                        FeatureRow(icon: "heart.fill", title: String(localized: L10n.Paywall.featureHealthKitTitle), description: String(localized: L10n.Paywall.featureHealthKitDescription), color: .pink)
                        FeatureRow(icon: "square.and.arrow.up", title: String(localized: L10n.Paywall.featureExportTitle), description: String(localized: L10n.Paywall.featureExportDescription), color: .blue)
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", title: String(localized: L10n.Paywall.featureAnalyticsTitle), description: String(localized: L10n.Paywall.featureAnalyticsDescription), color: .purple)
                    }
                    .padding(.horizontal)
                    
                    // Purchase Button
                    VStack(spacing: 16) {
                        if let product = storeManager.products.first(where: { $0.id == "trimtallypro" }) {
                            Button {
                                Task {
                                    let success = (try? await storeManager.purchase(product)) ?? false
                                    if success {
                                        dismiss()
                                    }
                                }
                            } label: {
                                HStack {
                                    if storeManager.isPurchasing {
                                        ProgressView()
                                            .accessibilityLabel(String(localized: L10n.Paywall.processingPurchaseLabel))
                                    }
                                    Text(L10n.Paywall.upgradeButton(product.displayPrice))
                                }
                                .font(.headline.bold())
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .accessibilityLabel(storeManager.isPurchasing ? String(localized: L10n.Paywall.processingPurchaseLabel) : String(localized: L10n.Paywall.upgradeButtonLabel(product.displayPrice)))
                            .accessibilityHint(storeManager.isPurchasing ? "" : String(localized: L10n.Paywall.upgradeButtonHint))
                            .padding(.horizontal)
                            .disabled(storeManager.isPurchasing)
                        } else {
                            ProgressView()
                                .padding()
                        }
                        
                        Button(String(localized: L10n.Paywall.restorePurchases)) {
                            Task {
                                await storeManager.restore()
                            }
                        }
                        .font(.footnote)
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .accessibilityHint(String(localized: L10n.Paywall.restoreButtonHint))
                    }
                }
                .padding(.bottom, 32)
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: L10n.Common.closeButton)) {
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
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
    }
}
