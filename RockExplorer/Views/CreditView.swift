//
//  CreditView.swift
//  RockExplorer
//
//  Created by Codex on 31/10/2568 BE.
//

import SwiftUI

struct CreditView: View {
    private let creators = [
        "ด.ญ. นภัสญาณ์ วัฒนสุภิญโญ",
        "ด.ช. วชิรวิชญ์ วัฒนสุภิญโญ",
        "ด.ช. ภูมิพัฒน์ ตันวิวัฒนกุล"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                section(title: "ความหมายของแอป RockExplorer") {
                    Text("แอปนี้สร้างขึ้นเพื่อให้ผู้เรียนได้รู้จักหินชนิดต่าง ๆ อย่างสนุกสนาน ผ่านเทคโนโลยี AR เราเชื่อว่าการเรียนรู้จะมีชีวิตชีวา เมื่อได้ “สำรวจ” ด้วยตนเอง")
                        .foregroundStyle(Color.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                section(title: "รายชื่อผู้จัดทำ") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(creators, id: \.self) { name in
                            Label(name, systemImage: "person.crop.circle.fill")
                                .foregroundStyle(Color.primaryText)
                        }
                    }
                }

                section(title: "อาจารย์ที่ปรึกษา") {
                    Label("อ. กฤษฏา ชัยจินดา", systemImage: "graduationcap.fill")
                        .foregroundStyle(Color.primaryText)
                }

                section(title: "ข้อความขอบคุณ") {
                    Text("ขอขอบคุณอาจารย์ที่ให้คำแนะนำ ทีมเพื่อนร่วมพัฒนา และทุกคนที่ช่วยให้แอปนี้เกิดขึ้นจริง แอปนี้จัดทำขึ้นเพื่อการเรียนรู้ และเป็นแรงบันดาลใจให้นักเรียนรักในวิทยาศาสตร์")
                        .foregroundStyle(Color.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding()
        }
        .navigationTitle("Credit")
        .navigationBarTitleDisplayMode(.inline)
        .background(
            LinearGradient(
                colors: [.backgroundPrimary, .backgroundSecondary.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RockExplorer")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.primaryText)

            Text("เรียนรู้ธรณีวิทยาผ่านเกมสำรวจหิน")
                .font(.title3)
                .foregroundStyle(Color.secondaryText)
        }
    }

    @ViewBuilder
    private func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.primaryText)

            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.surface)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 6)
        )
    }
}

#Preview {
    NavigationStack {
        CreditView()
    }
}
