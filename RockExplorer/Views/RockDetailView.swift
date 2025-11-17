//
//  RockDetailView.swift
//  RockExplorer
//
//  Created by Codex on 31/10/2568 BE.
//

import SwiftUI
import UIKit
import CoreLocation

struct RockDetailView: View {
    let rock: Rock

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                infoSection(title: "ชื่อภาษาอังกฤษ", value: rock.nameEN)
                infoSection(title: "ประเภทของหิน", value: rock.type)
                infoSection(title: "ความแข็ง (Mohs)", value: rock.hardness)

                Divider()

                infoSection(
                    title: "เกิดได้อย่างไร",
                    value: rock.description
                )
                infoSection(
                    title: "การใช้งาน",
                    value: rock.usage
                )

                if let location = rock.location {
                    let formatted = "ละติจูด \(String(format: "%.3f", location.latitude)), ลองจิจูด \(String(format: "%.3f", location.longitude))"
                    infoSection(title: "แหล่งที่พบ", value: formatted)
                }
            }
            .padding()
        }
        .navigationTitle(rock.nameTH)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.pastelPink.opacity(0.1).ignoresSafeArea())
        .onAppear {
            RockModelLoader.preloadModel(for: rock)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            RockImageView(rock: rock)
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )
                .shadow(radius: 12, y: 10)

            Text(rock.nameTH)
                .font(.largeTitle.bold())
                .foregroundStyle(Color.primaryText)

            Text(rock.nameEN)
                .font(.title3)
                .foregroundStyle(Color.secondaryText)

            NavigationLink {
                RockFocusView(rock: rock)
            } label: {
                Label("Focus Mode", systemImage: "arkit")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [.pastelPurple, .pastelBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func infoSection(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.secondaryText)

            Text(value)
                .font(.body)
                .foregroundStyle(Color.primaryText)
        }
    }
}

private struct RockImageView: View {
    let rock: Rock

    var body: some View {
        Group {
            if let image = RockImageProvider.image(for: rock) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(24)
            } else if let placeholder = UIImage(named: "placeholder") {
                Image(uiImage: placeholder)
                    .resizable()
                    .scaledToFit()
                    .padding(24)
            } else {
                Image(systemName: "cube.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(24)
                    .foregroundStyle(Color.pastelPurple)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }
}

#Preview {
    NavigationStack {
        RockDetailView(rock: RockDataStore.rocks.first ?? .placeholder)
    }
}
