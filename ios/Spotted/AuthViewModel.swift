import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    enum Step {
        case phone
        case otp
        case nickname
    }

    @Published var step: Step = .phone
    @Published var phoneE164: String = "+90"
    @Published var code: String = ""
    @Published var nickname: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var requestId: String? = nil
    @Published var isAuthenticated = false

    private let deviceId = UUID().uuidString

    func requestOTP() async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await APIClient.shared.requestOTP(phoneE164: phoneE164)
            requestId = response.requestId
            step = .otp
            return true
        } catch {
            errorMessage = mapAuthError(error)
            return false
        }
    }

    func verifyOTP() async {
        guard let requestId else {
            errorMessage = "Önce kod gönderin."
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await APIClient.shared.verifyOTP(requestId: requestId, code: code, deviceId: deviceId)
            UserDefaults.standard.set(response.accessToken, forKey: "access_token")
            if response.needsNickname ?? true {
                step = .nickname
            } else {
                isAuthenticated = true
            }
        } catch {
            errorMessage = mapAuthError(error)
        }
    }

    func submitNickname() async {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Takma ad boş olamaz."
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await APIClient.shared.updateNickname(trimmed)
            isAuthenticated = true
        } catch {
            errorMessage = mapAuthError(error)
        }
    }

    private func mapAuthError(_ error: Error) -> String {
        if let apiError = error as? APIError {
            switch apiError {
            case .http(_, let code, _):
                if let code, let msg = AppConfig.authErrorMessages[code] {
                    return msg
                }
                return apiError.localizedDescription
            default:
                return apiError.localizedDescription
            }
        }
        return error.localizedDescription
    }
}
