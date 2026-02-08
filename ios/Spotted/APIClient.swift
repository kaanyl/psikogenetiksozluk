import Foundation

enum APIError: LocalizedError {
    case http(status: Int, code: String?, message: String?)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .http(_, _, let message) where message != nil:
            return message
        case .http(let status, let code, _):
            if let code {
                return "Sunucu hatası (\(code))"
            }
            return "Sunucu hatası (HTTP \(status))"
        case .invalidResponse:
            return "Geçersiz sunucu yanıtı"
        }
    }
}

struct APIErrorResponse: Decodable {
    let code: String?
    let message: String?
    let error: String?
    let detail: String?
    let errors: [String]?
}

final class APIClient {
    static let shared = APIClient()

    private let baseURL = AppConfig.apiBaseURL
    private let session: URLSession
    private var accessToken: String? {
        UserDefaults.standard.string(forKey: "access_token")
    }

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: config)
    }

    private func makeRequest(path: String, method: String) -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = method
        if let token = accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    private func perform(_ req: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        if (200...299).contains(http.statusCode) {
            return data
        }
        let decoded = try? JSONDecoder.api.decode(APIErrorResponse.self, from: data)
        let message = decoded?.message ?? decoded?.error ?? decoded?.detail ?? decoded?.errors?.first
        throw APIError.http(status: http.statusCode, code: decoded?.code, message: message)
    }

    func getFeed(lat: Double, lng: Double, radiusKm: Double, cursor: String? = nil) async throws -> FeedResponse {
        if AppConfig.useMockServer {
            return await MockServer.shared.getFeed()
        }
        var components = URLComponents(url: baseURL.appendingPathComponent("/feed"), resolvingAgainstBaseURL: false)!
        var items = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lng", value: String(lng)),
            URLQueryItem(name: "radius_km", value: String(radiusKm))
        ]
        if let cursor {
            items.append(URLQueryItem(name: "cursor", value: cursor))
        }
        components.queryItems = items
        var req = makeRequest(path: "/feed", method: "GET")
        req.url = components.url
        let data = try await perform(req)
        return try JSONDecoder.api.decode(FeedResponse.self, from: data)
    }

    func getPostDetail(postId: UUID, cursor: String? = nil) async throws -> PostDetailResponse {
        if AppConfig.useMockServer {
            return await MockServer.shared.getPostDetail(postId: postId)
        }
        var components = URLComponents(url: baseURL.appendingPathComponent("/posts/\(postId.uuidString)"), resolvingAgainstBaseURL: false)!
        if let cursor {
            components.queryItems = [URLQueryItem(name: "cursor", value: cursor)]
        }
        var req = makeRequest(path: "/posts/\(postId.uuidString)", method: "GET")
        req.url = components.url
        let data = try await perform(req)
        return try JSONDecoder.api.decode(PostDetailResponse.self, from: data)
    }

    func createPost(_ request: PostCreateRequest) async throws -> UUID {
        if AppConfig.useMockServer {
            await MockServer.shared.createPost(request)
            return UUID()
        }
        var req = makeRequest(path: "/posts", method: "POST")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder.api.encode(request)
        let data = try await perform(req)
        let response = try JSONDecoder.api.decode(PostCreateResponse.self, from: data)
        return response.id
    }

    func vote(postId: UUID, value: Int) async throws {
        if AppConfig.useMockServer {
            await MockServer.shared.vote(postId: postId, value: value)
            return
        }
        if value == 0, AppConfig.voteZeroUsesDelete {
            let req = makeRequest(path: "/posts/\(postId.uuidString)/vote", method: "DELETE")
            _ = try await perform(req)
            return
        }
        var req = makeRequest(path: "/posts/\(postId.uuidString)/vote", method: "POST")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder.api.encode(VoteRequest(value: value))
        _ = try await perform(req)
    }

    func createComment(postId: UUID, text: String) async throws {
        if AppConfig.useMockServer {
            await MockServer.shared.createComment(postId: postId, text: text)
            return
        }
        var req = makeRequest(path: "/posts/\(postId.uuidString)/comments", method: "POST")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder.api.encode(CommentCreateRequest(text: text))
        _ = try await perform(req)
    }

    func uploadPhoto(data: Data, filename: String? = nil) async throws -> String {
        if AppConfig.useMockServer {
            return await MockServer.shared.uploadPhoto()
        }
        let boundary = "Boundary-\(UUID().uuidString)"
        let name = filename ?? "photo.\(AppConfig.mediaFileExtension)"
        var req = makeRequest(path: AppConfig.mediaUploadPath, method: "POST")
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(AppConfig.mediaFormFieldName)\"; filename=\"\(name)\"\r\n")
        body.appendString("Content-Type: \(AppConfig.mediaMimeType)\r\n\r\n")
        body.append(data)
        body.appendString("\r\n--\(boundary)--\r\n")
        req.httpBody = body

        let data = try await perform(req)
        let response = try JSONDecoder.api.decode(MediaUploadResponse.self, from: data)
        return response.url
    }

    func requestOTP(phoneE164: String) async throws -> OTPRequestResponse {
        if AppConfig.useMockServer {
            return await MockServer.shared.requestOTP()
        }
        var req = makeRequest(path: "/auth/otp/request", method: "POST")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder.api.encode(OTPRequest(phoneE164: phoneE164))
        let data = try await perform(req)
        return try JSONDecoder.api.decode(OTPRequestResponse.self, from: data)
    }

    func verifyOTP(requestId: String, code: String, deviceId: String) async throws -> OTPVerifyResponse {
        if AppConfig.useMockServer {
            return await MockServer.shared.verifyOTP()
        }
        var req = makeRequest(path: "/auth/otp/verify", method: "POST")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder.api.encode(OTPVerifyRequest(requestId: requestId, code: code, deviceId: deviceId))
        let data = try await perform(req)
        return try JSONDecoder.api.decode(OTPVerifyResponse.self, from: data)
    }

    func updateNickname(_ nickname: String) async throws {
        if AppConfig.useMockServer {
            await MockServer.shared.updateNickname()
            return
        }
        var req = makeRequest(path: "/profile", method: "POST")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder.api.encode(ProfileUpdateRequest(nickname: nickname))
        _ = try await perform(req)
    }
}

extension JSONDecoder {
    static var api: JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }
}

extension JSONEncoder {
    static var api: JSONEncoder {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .iso8601
        return e
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
