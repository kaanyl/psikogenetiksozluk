import Foundation

enum AppConfig {
    static let useMockServer = true

    static let apiBaseURL: URL = {
        let key = "API_BASE_URL"
        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
           let url = URL(string: value) {
            return url
        }
        return URL(string: "https://api.example.com")!
    }()

    static let mediaUploadPath = "/media/upload"
    static let mediaFormFieldName = "file"
    static let mediaMimeType = "image/jpeg"
    static let mediaFileExtension = "jpg"

    static let sponsorEvery = 8
    static let otpResendSeconds = 30

    static let voteZeroUsesDelete = true

    static let authErrorMessages: [String: String] = [
        "otp_invalid": "Kod hatalı.",
        "otp_expired": "Kodun süresi doldu.",
        "otp_rate_limited": "Çok fazla deneme yapıldı. Lütfen bekleyin.",
        "phone_blocked": "Bu numara geçici olarak engellendi.",
        "nickname_taken": "Takma ad kullanımda."
    ]
}
