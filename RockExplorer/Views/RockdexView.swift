//
//  RockdexView.swift
//  RockExplorer
//
//  Created by Codex on 31/10/2568 BE.
//

import SwiftUI
import UIKit

struct RockdexView: View {
    @EnvironmentObject private var collection: RockCollectionViewModel
    let onSelect: (Rock) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HeaderView(collectedCount: collection.collectedRocks.count, total: collection.allRocks.count)

                if collection.collectedRocks.isEmpty {
                    EmptyStateView()
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(collection.collectedRocks, id: \.id) { rock in
                            RockdexCard(rock: rock) {
                                onSelect(rock)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("My Rockdex")
        .background(
            LinearGradient(
                colors: [.backgroundPrimary, .backgroundSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}

private struct HeaderView: View {
    let collectedCount: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("รวบรวมหินให้ครบทั้ง \(total) ชนิด!")
                .font(.title3.bold())
                .foregroundStyle(Color.primaryText)

            HStack(spacing: 12) {
                ProgressView(value: Double(collectedCount), total: Double(max(total, 1)))
                    .progressViewStyle(.linear)
                    .tint(.pastelPurple)
                    .frame(height: 8)
                    .clipShape(Capsule())

                Text("\(collectedCount)/\(total)")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(Color.secondaryText)
            }
        }
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(Color.pastelPurple)

            Text("ยังไม่มีหินใน Rockdex")
                .font(.headline)
                .foregroundStyle(Color.primaryText)

            Text("เริ่มออกสำรวจด้วย Radar Mode เพื่อเก็บหินชิ้นแรกของคุณ")
                .font(.subheadline)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.surfaceSoft)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 6)
        )
    }
}

private struct RockdexCard: View {
    let rock: Rock
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                rockImageView
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(radius: 4, y: 3)

                VStack(alignment: .leading, spacing: 6) {
                    Text(rock.nameTH)
                        .font(.headline)
                        .foregroundStyle(Color.primaryText)
                    Text(rock.nameEN)
                        .font(.subheadline)
                        .foregroundStyle(Color.secondaryText)
                    Text(rock.type)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.pastelPurple.gradient)
                        )
                }

            Spacer()

            Image(systemName: "chevron.forward")
                .foregroundStyle(Color.secondaryText)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.surface)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 6)
        )
    }
    .buttonStyle(.plain)
}
}

private extension RockdexCard {
    @ViewBuilder
    var rockImageView: some View {
        if let image = UIImage(named: rock.imageName) ?? UIImage(named: rock.assetName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if let placeholder = UIImage(named: "placeholder") {
            Image(uiImage: placeholder)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "cube.fill")
                .resizable()
                .scaledToFit()
                .padding(12)
                .foregroundStyle(Color.pastelPurple)
        }
    }
}

#Preview {
    RockdexView(onSelect: { _ in })
        .environmentObject(RockCollectionViewModel())
}
