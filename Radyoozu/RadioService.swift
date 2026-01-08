import Foundation

struct SongInfo {
    let title: String
    let isLive: Bool
}

actor RadioService {
    static let shared = RadioService()

    private let stationId = "s3ab6bdcb9"
    private var baseURL: URL {
        URL(string: "https://public.radio.co/stations/\(stationId)/status")!
    }

    func fetchStatus() async throws -> RadioStatus {
        let (data, response) = try await URLSession.shared.data(from: baseURL)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw RadioError.invalidResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode(RadioStatus.self, from: data)
    }

    func getCurrentSong() async -> SongInfo {
        do {
            let status = try await fetchStatus()
            if status.status == "offline" {
                return SongInfo(title: "Offline", isLive: false)
            }
            let title = status.currentTrack?.title ?? "No track info"
            return SongInfo(title: title, isLive: status.isLive)
        } catch {
            return SongInfo(title: "Error", isLive: false)
        }
    }
}

enum RadioError: Error {
    case invalidResponse
    case decodingError
}
