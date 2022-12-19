//
//  OnboardingContent.swift
//  Sinusbot Soundboard
//
//  Created by Bernardo Ruiz  on 19/12/22.
//

import AlertToast
import KeychainAccess
import SwiftUI

struct OnboardingContent: View {
    @Environment(\.dismiss) private var dismiss
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var url: String = ""
    @State private var showToast: Bool = false
    @State private var toastTitle: String = ""
    @State private var toastType: AlertToast.AlertType = .regular

    var body: some View {
        Form {
            Text("Settings")
                .font(.title)
            HStack {
                Text("Bot URL")
                    .frame(width: 85)
                Divider()
                TextField("https://bot.example.com/api/v1", text: $url)
                    .scrollDismissesKeyboard(.automatic)
                    .textContentType(.URL)
                    .keyboardType(.webSearch)
            }
            HStack {
                Text("Username")
                    .frame(width: 85)
                Divider()
                TextField("admin", text: $username)
                    .scrollDismissesKeyboard(.automatic)
                    .textContentType(.username)
                    .textCase(.lowercase)
                    .keyboardType(.default)
            }
            HStack {
                Text("Password")
                    .frame(width: 85)
                Divider()
                SecureField("", text: $password)
                    .scrollDismissesKeyboard(.automatic)
                    .textContentType(.password)
                    .textCase(.lowercase)
            }

            Button("Continue", action: handleContinue)
        }
        .onAppear {
            Task {
                await initOnboarding()
            }
        }
        .toast(isPresenting: $showToast) {
            AlertToast(displayMode: .banner(.pop), type: toastType, title: toastTitle)
        }
        .interactiveDismissDisabled()
    }

    func initOnboarding() async {
        DispatchQueue.global().async {
            do {
                let keychain = Keychain(service: "dev.bernardo.ruiz.Sinusbot-Soundboard")
                    .synchronizable(true)
                username = try keychain
                    .get("username") ?? ""
                password = try keychain
                    .get("password") ?? ""
                url = try keychain
                    .get("url") ?? ""
            } catch {
                print(error)
            }
        }
    }

    func handleContinue() {
        DispatchQueue.global().async {
            do {
                print("running continue")
                let keychain = Keychain(service: "dev.bernardo.ruiz.Sinusbot-Soundboard")
                try keychain
                    .set(username, key: "username")
                try keychain
                    .set(password, key: "password")
                try keychain
                    .set(url, key: "url")
                Task {
                    let testCreds = await login()
                    if testCreds != nil, testCreds! {
                        toastTitle = "Logged In"
                        toastType = .complete(.green)
                        showToast.toggle()
                        try await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
                        UserDefaults.standard.set(true, forKey: "isOnboarded")
                        dismiss()
                    } else {
                        toastTitle = "Failed to loggin, check credentials"
                        toastType = .error(.red)
                        showToast.toggle()
                    }
                }
            } catch {
                print(error)
            }
        }
    }
}

struct OnboardingContent_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingContent()
    }
}
