//
//  ContentView.swift
//  RockExplorer
//
//  Created by Codex on 31/10/2568 BE.
//

import SwiftUI

struct ContentView: View {
    @State private var showSplash = true
    @State private var path = NavigationPath()
    @State private var isNavigatingToRadar = false

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                NavigationStack(path: $path) {
                    MainMenuView(
                        onExplore: {
                            isNavigatingToRadar = true
                            path.append(Destination.radar)
                        },
                        onRockdex: { path.append(Destination.rockdex) },
                        onCredits: { path.append(Destination.credit) }
                    )
                    .navigationDestination(for: Destination.self) { destination in
                        switch destination {
                        case .radar:
                            RadarView(onReady: { isNavigatingToRadar = false })
                                .navigationBarTitleDisplayMode(.inline)
                        case .rockdex:
                            RockdexView { rock in
                                path.append(Destination.rockDetail(rock))
                            }
                            .navigationBarTitleDisplayMode(.inline)
                        case .credit:
                            CreditView()
                                .navigationBarTitleDisplayMode(.inline)
                        case let .rockDetail(rock):
                            RockDetailView(rock: rock)
                                .navigationBarTitleDisplayMode(.inline)
                        }
                    }
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeInOut(duration: 0.6)) {
                showSplash = false
            }
        }
        .preferredColorScheme(.light)
        .overlay {
            if isNavigatingToRadar {
                ZStack {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                    ProgressView("กำลังเปิด Radar...")
                        .progressViewStyle(.circular)
                        .tint(Color.pastelPurple)
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.white.opacity(0.9))
                        )
                }
            }
        }
    }
}

private enum Destination: Hashable {
    case radar
    case rockdex
    case credit
    case rockDetail(Rock)
}

#Preview {
    ContentView()
        .environmentObject(RockCollectionViewModel())
        .environmentObject(LocationService())
        .environmentObject(RadarViewModel(collection: RockCollectionViewModel()))
}
