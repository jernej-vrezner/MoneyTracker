//
//  OnboardingView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 3. 11. 2026.
//

import SwiftUI
import SwiftData

struct OnboardingPage {
    let icon: String
    let color: Color
    let title: String
    let text: String
}

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    @Query private var accounts: [Account]
    @State private var page = 0

    let onFinish: () -> Void

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "lock.shield.fill",
            color: Color.accentColor,
            title: "Dobrodošel v MoneyTracker",
            text: "Pregled nad denarjem, ki ostane na tvojem telefonu. Brez računa, brez prijave."
        ),
        OnboardingPage(
            icon: "plus.circle.fill",
            color: Color("positiveColor"),
            title: "Vnašaj hitro",
            text: "Plavajoči gumb \"+\" ali widget na domačem zaslonu: odliv ali priliv v dveh tapih."
        ),
        OnboardingPage(
            icon: "building.columns.fill",
            color: Color.blue,
            title: "Računi, kategorije in budget",
            text: "Razdeli denar po računih in nastavi mesečne limite po kategorijah, da veš, koliko ti še ostane."
        ),
        OnboardingPage(
            icon: "chart.pie.fill",
            color: Color.orange,
            title: "Statistika, naložbe, cilji",
            text: "Spremljaj, kam gre denar, kako raste portfelj in kako blizu si svojim ciljem."
        )
    ]

    private var lastIndex: Int { pages.count }
    private var isEmptyStart: Bool { categories.isEmpty && accounts.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if page < lastIndex {
                    Button("Preskoči") { onFinish() }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color("textSecondary"))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .frame(height: 44)

            TabView(selection: $page) {
                ForEach(0..<pages.count, id: \.self) { index in
                    pageView(pages[index]).tag(index)
                }
                finalPage.tag(lastIndex)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 8) {
                ForEach(0...lastIndex, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? Color.accentColor : Color("textSecondary").opacity(0.3))
                        .frame(width: index == page ? 22 : 8, height: 8)
                }
            }
            .padding(.vertical, 16)

            if page < lastIndex {
                Button {
                    withAnimation { page += 1 }
                } label: {
                    Text("Naprej")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            } else {
                Color.clear.frame(height: 24)
            }
        }
        .background(Color("appBackground"))
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: page.icon)
                .font(.system(size: 54))
                .foregroundStyle(page.color)
                .frame(width: 120, height: 120)
                .background(page.color.opacity(0.15))
                .clipShape(Circle())
            Text(page.title)
                .font(.title.weight(.bold))
                .foregroundStyle(Color("textPrimary"))
                .multilineTextAlignment(.center)
            Text(page.text)
                .font(.body)
                .foregroundStyle(Color("textSecondary"))
                .multilineTextAlignment(.center)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var finalPage: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 54))
                .foregroundStyle(Color.accentColor)
                .frame(width: 120, height: 120)
                .background(Color.accentColor.opacity(0.15))
                .clipShape(Circle())
            Text("Pripravljen?")
                .font(.title.weight(.bold))
                .foregroundStyle(Color("textPrimary"))
            Text(isEmptyStart
                 ? "Lahko začneš s predlaganimi kategorijami in prvim računom, ali pa vse nastaviš sam."
                 : "Vse je nastavljeno. Veselo spremljanje!")
                .font(.body)
                .foregroundStyle(Color("textSecondary"))
                .multilineTextAlignment(.center)

            Spacer()

            if isEmptyStart {
                Button {
                    createStarterSetup()
                    onFinish()
                } label: {
                    Text("Začni s predlaganimi kategorijami")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                Button("Začni prazno") { onFinish() }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color("textSecondary"))
                    .padding(.top, 4)
            } else {
                Button {
                    onFinish()
                } label: {
                    Text("Zapri")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private func createStarterSetup() {
        modelContext.insert(Account(name: "Glavni račun", kind: .bank, initialBalance: 0, color: .blue))

        let starter: [(String, CategoryColor, Decimal, String)] = [
            ("Hrana", .red, 300, "fork.knife"),
            ("Dom", .blue, 400, "house.fill"),
            ("Prevoz", .teal, 120, "car.fill"),
            ("Zabava", .purple, 80, "gamecontroller.fill"),
            ("Nakupovanje", .pink, 100, "bag.fill")
        ]
        for (name, color, limit, icon) in starter {
            modelContext.insert(Category(name: name, color: color, monthlyLimit: limit, icon: icon))
        }
    }
}
