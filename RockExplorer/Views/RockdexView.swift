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
            Text("ท่านรวบรวมหินได้ \(collectedCount) ชนิด จากทั้งหมด \(total) ชนิด")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.primaryText)

            AchievementStepsView(
                collectedCount: collectedCount,
                total: total
            )
        }
    }
}

private struct AchievementStepsView: View {
    let collectedCount: Int
    let total: Int

    private var steps: [AchievementStep] {
        let safeTotal = max(total, 1)
        let bronzePercent = 0.3
        let silverPercent = 0.68
        let goldPercent = 1.0

        let bronze = max(1, Int(ceil(Double(safeTotal) * bronzePercent)))
        let silver = max(bronze, Int(ceil(Double(safeTotal) * silverPercent)))
        let gold = safeTotal

        return [
            AchievementStep(
                title: "ทองแดง",
                systemImage: "medal.fill",
                color: Color(red: 181 / 255, green: 120 / 255, blue: 87 / 255),
                percent: bronzePercent,
                threshold: bronze
            ),
            AchievementStep(
                title: "เงิน",
                systemImage: "medal.fill",
                color: Color(red: 196 / 255, green: 206 / 255, blue: 214 / 255),
                percent: silverPercent,
                threshold: silver
            ),
            AchievementStep(
                title: "ทอง",
                systemImage: "medal.fill",
                color: Color(red: 240 / 255, green: 201 / 255, blue: 86 / 255),
                percent: goldPercent,
                threshold: gold
            )
        ]
    }

    var body: some View {
        GeometryReader { geo in
            let lineStart: CGFloat = 12
            let lineEnd = max(lineStart, geo.size.width - 12)
            let lineWidth = max(0, lineEnd - lineStart)
            let badgeWidth: CGFloat = 60
            ZStack(alignment: .topLeading) {
                Capsule()
                    .fill(Color.secondaryText.opacity(0.2))
                    .frame(width: lineWidth, height: 4)
                    .padding(.horizontal, 12)
                    .padding(.top, 16)

                Capsule()
                    .fill(Color.pastelPurple)
                    .frame(width: max(12, lineWidth * progress), height: 4)
                    .padding(.horizontal, 12)
                    .padding(.top, 16)

                ForEach(steps) { step in
                    let rawX = lineStart + (lineWidth * CGFloat(step.percent))
                    let clampedX = min(max(rawX, lineStart + badgeWidth / 2), lineEnd - badgeWidth / 2)
                    AchievementStepBadge(
                        step: step,
                        isComplete: collectedCount >= step.threshold
                    )
                    .frame(width: badgeWidth)
                    .position(x: clampedX, y: 32)
                }
            }
        }
        .frame(height: 70)
    }

    private var progress: CGFloat {
        let safeTotal = max(total, 1)
        return CGFloat(min(Double(collectedCount) / Double(safeTotal), 1))
    }
}

private struct AchievementStep: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let color: Color
    let percent: Double
    let threshold: Int
}

private struct AchievementStepBadge: View {
    let step: AchievementStep
    let isComplete: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: step.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(step.color.opacity(isComplete ? 1 : 0.45))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(step.color.opacity(isComplete ? 0.18 : 0.08))
                        .overlay(
                            Circle()
                                .stroke(Color.secondaryText.opacity(0.2), lineWidth: 1)
                        )
                )

            Text(step.title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.secondaryText)
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
        if let image = RockImageProvider.image(for: rock) {
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
