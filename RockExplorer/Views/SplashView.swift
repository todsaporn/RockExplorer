//
//  SplashView.swift
//  RockExplorer
//
//  Created by Codex on 31/10/2568 BE.
//

import SwiftUI

struct SplashView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.pastelPink, .pastelBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Image("rock_explorer_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .scaleEffect(animate ? 1.05 : 0.9)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animate)

                Text("RockExplorer")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text("สำรวจหินรอบตัวด้วยเทคโนโลยี AR")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .onAppear {
            animate = true
        }
    }
}

#Preview {
    SplashView()
}
