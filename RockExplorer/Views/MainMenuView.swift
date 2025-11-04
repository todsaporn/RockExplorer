//
//  MainMenuView.swift
//  RockExplorer
//
//  Created by Codex on 31/10/2568 BE.
//

import SwiftUI
import UIKit

struct MainMenuView: View {
    let onExplore: () -> Void
    let onRockdex: () -> Void
    let onCredits: () -> Void

    private let buttonGradient = LinearGradient(
        colors: [.pastelPurple, .pastelBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.pastelBlue.opacity(0.6), .pastelPink.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                logoView
                    .frame(maxWidth: .infinity)
                    .padding(.top, 48)

                VStack(spacing: 8) {
                    Text("RockExplorer")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.primaryText)
                    Text("เรียนรู้ธรณีวิทยาผ่านเกมสำรวจหิน")
                        .font(.headline)
                        .foregroundStyle(Color.secondaryText)
                }

                VStack(spacing: 18) {
                    Button(action: onExplore) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Explore")
                                .font(.title3.bold())
                                .foregroundColor(.black)
                            Text("เปิด Radar Mode เพื่อค้นหาหินใกล้ตัว")
                                .font(.subheadline)
                                .foregroundColor(.black.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            buttonGradient
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 6)
                        )
                    }
                    .buttonStyle(.plain)

                    Button(action: onRockdex) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("My Rockdex")
                                .font(.title3.bold())
                                .foregroundColor(.black)
                            Text("สะสมและทบทวนหินที่ค้นพบ")
                                .font(.subheadline)
                                .foregroundColor(.black.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.pastelGreen, .pastelYellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 6)
                        )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button(action: onCredits) {
                    Text("Credit")
                        .font(.headline)
                        .foregroundStyle(Color.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.primaryText.opacity(0.2), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color.white.opacity(0.6))
                                )
                        )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
        .navigationBarBackButtonHidden()
    }
}

private extension MainMenuView {
    var logoView: some View {
        Group {
            if let path = Bundle.main.path(forResource: "rock_explorer_logo", ofType: "png", inDirectory: "Resources/Images"),
               let image = UIImage(contentsOfFile: path) {
                Image(uiImage: image)
                    .resizable()
            } else if let image = UIImage(named: "rock_explorer_logo") {
                Image(uiImage: image)
                    .resizable()
            } else {
                Image(systemName: "mountain.2.fill")
                    .resizable()
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.pastelPurple, Color.pastelBlue)
            }
        }
        .scaledToFit()
        .frame(height: 140)
        .shadow(color: .black.opacity(0.12), radius: 12, y: 8)
    }
}

private struct MainMenuButton: View {
    let title: String
    let subtitle: String
    let gradient: LinearGradient
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                gradient
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 6)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainMenuView(onExplore: {}, onRockdex: {}, onCredits: {})
}
