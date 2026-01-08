import Foundation

struct RadioStatus: Codable {
    let status: String
    let source: Source?
    let currentTrack: CurrentTrack?

    struct Source: Codable {
        let type: String
    }

    struct CurrentTrack: Codable {
        let title: String
        let artworkUrl: String?
        let artworkUrlLarge: String?
        let startTime: String?

        enum CodingKeys: String, CodingKey {
            case title
            case artworkUrl = "artwork_url"
            case artworkUrlLarge = "artwork_url_large"
            case startTime = "start_time"
        }
    }

    enum CodingKeys: String, CodingKey {
        case status
        case source
        case currentTrack = "current_track"
    }

    var isLive: Bool {
        source?.type == "live"
    }
}
