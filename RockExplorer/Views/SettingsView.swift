//
//  SettingsView.swift
//  RockExplorer
//
//  Created by Codex on 31/10/2568 BE.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: GameSettings
    @EnvironmentObject private var collection: RockCollectionViewModel
    @EnvironmentObject private var radarViewModel: RadarViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var detectionRadius: Double = 5
    @State private var searchRadius: Double = 50
    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    settingCard(
                        title: "ระยะพบหิน",
                        subtitle: "ปรับระยะที่ต้องเข้าใกล้เพื่อปลดล็อกหิน",
                        content: detectionSlider
                    )

                    settingCard(
                        title: "ความกว้างของพื้นที่",
                        subtitle: "กำหนดรัศมีการสุ่มตำแหน่งหินรอบตัว",
                        content: searchRadiusSlider
                    )

                    resetCard
                }
                .padding()
            }
            .navigationTitle("ตั้งค่า")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ปิด") { dismiss() }
                }
            }
            .alert("ยืนยันเริ่มใหม่", isPresented: $showResetConfirmation) {
                Button("เริ่มใหม่", role: .destructive, action: resetProgress)
                Button("ยกเลิก", role: .cancel) { }
            } message: {
                Text("ต้องการยกเลิกการพบหินทั้งหมดและเริ่มใหม่ใช่หรือไม่")
            }
            .onAppear {
                detectionRadius = settings.detectionRadius
                searchRadius = settings.searchRadius
            }
            .onChange(of: detectionRadius) { newValue in
                settings.detectionRadius = newValue
            }
            .onChange(of: searchRadius) { newValue in
                settings.searchRadius = newValue
            }
        }
    }

    private func settingCard<Content: View>(
        title: String,
        subtitle: String,
        content: Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)
            }

            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.surface)
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    private var detectionSlider: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ค่าเดิม: 5 m")
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)
                Spacer()
                Text("\(detectionRadius.formatted(.number.precision(.fractionLength(0...1)))) m")
                    .font(.headline.monospacedDigit())
            }

            Slider(value: $detectionRadius, in: 5...10, step: 0.5)
        }
    }

    private var searchRadiusSlider: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ค่าเดิม: 50 m")
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)
                Spacer()
                Text("\(searchRadius.formatted(.number.precision(.fractionLength(0)))) m")
                    .font(.headline.monospacedDigit())
            }

            Slider(value: $searchRadius, in: 50...200, step: 10)
        }
    }

    private var resetCard: some View {
        settingCard(
            title: "รีเซ็ตความคืบหน้า",
            subtitle: "ล้างการพบหินทั้งหมดและเริ่มเล่นใหม่",
            content:
                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                        Text("Reset ล้างการพบหินทั้งหมด")
                        Spacer()
                        Image(systemName: "chevron.forward")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(Color.red)
                    .padding(.vertical, 6)
                }
        )
    }

    private func resetProgress() {
        collection.resetCollection()
        radarViewModel.reset()
    }
}

#Preview {
    let collection = RockCollectionViewModel()
    let settings = GameSettings()
    return SettingsView()
        .environmentObject(settings)
        .environmentObject(collection)
        .environmentObject(RadarViewModel(collection: collection))
}
