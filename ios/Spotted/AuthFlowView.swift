import SwiftUI

@MainActor
struct AuthFlowView: View {
    @StateObject private var viewModel = AuthViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var resendSecondsLeft: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if viewModel.step == .phone {
                    Text("Telefon Doğrulama")
                        .font(.title2)
                        .bold()

                    TextField("+90 5xx xxx xx xx", text: $viewModel.phoneE164)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.phonePad)

                    Button("Kod Gönder") {
                        Task {
                            let ok = await viewModel.requestOTP()
                            if ok { startResendCountdown() }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                if viewModel.step == .otp {
                    Text("OTP Kodu")
                        .font(.title2)
                        .bold()

                    TextField("OTP Kodu", text: $viewModel.code)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)

                    Button("Doğrula") {
                        Task { await viewModel.verifyOTP() }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)

                    Button(resendSecondsLeft > 0 ? "Yeniden gönder (\(resendSecondsLeft))" : "Yeniden gönder") {
                        Task {
                            let ok = await viewModel.requestOTP()
                            if ok { startResendCountdown() }
                        }
                    }
                    .disabled(resendSecondsLeft > 0)
                    .foregroundColor(resendSecondsLeft > 0 ? .gray : .blue)

                    Button("Geri") {
                        viewModel.step = .phone
                    }
                    .foregroundColor(.gray)
                }

                if viewModel.step == .nickname {
                    Text("Takma Ad")
                        .font(.title2)
                        .bold()

                    TextField("Takma ad", text: $viewModel.nickname)
                        .textFieldStyle(.roundedBorder)

                    Button("Devam") {
                        Task { await viewModel.submitNickname() }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                if viewModel.isLoading {
                    ProgressView().padding(.top, 8)
                }

                if let error = viewModel.errorMessage {
                    Text(error).foregroundColor(.red).font(.footnote)
                }

                Spacer()
            }
            .padding(16)
        }
        .onChange(of: viewModel.isAuthenticated) { newValue in
            if newValue {
                appState.refreshAuth()
            }
        }
    }

    private func startResendCountdown() {
        resendSecondsLeft = AppConfig.otpResendSeconds
        Task {
            while resendSecondsLeft > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                resendSecondsLeft -= 1
            }
        }
    }
}

#Preview {
    AuthFlowView()
}
