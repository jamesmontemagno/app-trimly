import SwiftUI

struct PresentationSettingsView: View {
    @EnvironmentObject private var deviceSettings: DeviceSettingsStore
    @Environment(\.dismiss) private var dismiss

    private var cards: [DashboardCard] { deviceSettings.presentation.dashboardCards }
    private var hiddenCards: [DashboardCard] { DashboardCard.allCases.filter { !cards.contains($0) } }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(String(localized: L10n.Portability.hideWeights), isOn: Binding(
                        get: { deviceSettings.presentation.hideWeights },
                        set: { value in deviceSettings.updatePresentation { $0.hideWeights = value } }
                    ))
                    .accessibilityLabel(Text(L10n.Portability.hideWeights))
                    .accessibilityHint(Text(L10n.Portability.hideWeightsHint))
                } header: {
                    Text(L10n.Portability.privacy)
                } footer: {
                    Text(L10n.Portability.deviceLocal)
                    Text(L10n.Portability.hideWeightsHint)
                }
                Section {
                    ForEach(cards) { card in
                        VStack(alignment: .leading) {
                            Text(L10n.Portability.cardTitle(card)).font(.headline)
                            HStack {
                                cardButton("arrow.up", title: L10n.Portability.moveUp(card), disabled: cards.first == card) {
                                    move(card, by: -1)
                                }
                                cardButton("arrow.down", title: L10n.Portability.moveDown(card), disabled: cards.last == card) {
                                    move(card, by: 1)
                                }
                                Spacer()
                                cardButton("eye.slash", title: L10n.Portability.hideCard(card)) {
                                    deviceSettings.updatePresentation { $0.dashboardCards.removeAll { $0 == card } }
                                }
                            }
                        }
                        .accessibilityElement(children: .contain)
                    }
                    .onMove { source, destination in
                        deviceSettings.updatePresentation { $0.dashboardCards.move(fromOffsets: source, toOffset: destination) }
                    }
                } header: {
                    Text(L10n.Portability.visibleCards)
                } footer: {
                    Text(L10n.Portability.reorderHint)
                }
                if !hiddenCards.isEmpty {
                    Section {
                        ForEach(hiddenCards) { card in
                            Button {
                                deviceSettings.updatePresentation { $0.dashboardCards.append(card) }
                            } label: {
                                Label(String(localized: L10n.Portability.cardTitle(card)), systemImage: "plus")
                                    .frame(minHeight: 44)
                            }
                            .accessibilityLabel(Text(L10n.Portability.showCard(card)))
                        }
                    } header: {
                        Text(L10n.Portability.hiddenCards)
                    }
                }
                Section {
                    Button(String(localized: L10n.Portability.resetCards)) {
                        deviceSettings.updatePresentation { $0.dashboardCards = DashboardCard.allCases }
                    }
                    .accessibilityLabel(Text(L10n.Portability.resetCards))
                }
            }
            .navigationTitle(Text(L10n.Portability.presentationTitle))
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .primaryAction) { EditButton() }
                #endif
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: L10n.Common.doneButton)) { dismiss() }
                        .accessibilityLabel(Text(L10n.Common.doneButton))
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 560)
        #endif
    }

    private func cardButton(_ icon: String, title: LocalizedStringResource, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(Text(title))
        .disabled(disabled)
    }

    private func move(_ card: DashboardCard, by offset: Int) {
        guard let index = cards.firstIndex(of: card), cards.indices.contains(index + offset) else { return }
        deviceSettings.updatePresentation { $0.dashboardCards.swapAt(index, index + offset) }
    }
}
