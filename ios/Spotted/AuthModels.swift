import Foundation

struct OTPRequest: Encodable {
    let phoneE164: String
}

struct OTPVerifyRequest: Encodable {
    let requestId: String
    let code: String
    let deviceId: String
}

struct OTPRequestResponse: Decodable {
    let requestId: String
}

struct OTPVerifyResponse: Decodable {
    let accessToken: String
    let userId: String
    let needsNickname: Bool?
}
