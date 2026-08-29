import Foundation
import SwiftUI

enum RelationshipTier: String, Codable, CaseIterable, Identifiable, Sendable {
    case close, important, familiar, occasional, custom

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var cadenceDescription: String {
        self == .custom ? "Individual schedules" : "Every \(defaultInterval) days"
    }
    var symbol: String {
        switch self {
        case .close: "person.2.fill"
        case .important: "star.fill"
        case .familiar: "person.crop.circle"
        case .occasional: "calendar"
        case .custom: "slider.horizontal.3"
        }
    }
    var defaultInterval: Int {
        switch self {
        case .close: 7
        case .important: 15
        case .familiar: 30
        case .occasional: 60
        case .custom: 21
        }
    }
    var priority: Double {
        switch self {
        case .close: 4
        case .important: 3
        case .familiar: 2
        case .occasional: 1
        case .custom: 2.5
        }
    }
}

enum InteractionType: String, Codable, CaseIterable, Identifiable, Sendable {
    case message, call, videoCall, voiceNote, inPerson, group, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .videoCall: "Video call"
        case .voiceNote: "Voice note"
        case .inPerson: "In person"
        case .group: "Group"
        default: rawValue.capitalized
        }
    }
    var symbol: String {
        switch self {
        case .message: "message.fill"
        case .call: "phone.fill"
        case .videoCall: "video.fill"
        case .voiceNote: "waveform"
        case .inPerson: "person.2.fill"
        case .group: "person.3.fill"
        case .other: "ellipsis"
        }
    }
}

enum InteractionQuality: String, Codable, CaseIterable, Identifiable, Sendable {
    case quick, good, meaningful, inPerson
    var id: String { rawValue }
    var title: String {
        switch self {
        case .quick: "Quick check-in"
        case .good: "Good conversation"
        case .meaningful: "Meaningful"
        case .inPerson: "Met in person"
        }
    }
}

enum MemoryCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case general, work, family, interests, travel, health, plans
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum MemoryLifespan: String, Codable, CaseIterable, Identifiable, Sendable {
    case permanent, longTerm, temporary, eventSpecific
    var id: String { rawValue }
    var title: String {
        switch self {
        case .longTerm: "Long-term"
        case .eventSpecific: "Event-specific"
        default: rawValue.capitalized
        }
    }
}

enum ImportantDateKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case birthday, anniversary, event, custom
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum ContactChannel: String, Codable, CaseIterable, Identifiable, Sendable {
    case messages, phone, faceTime, whatsApp, telegram, instagram
    var id: String { rawValue }
    var title: String {
        switch self {
        case .faceTime: "FaceTime"
        case .whatsApp: "WhatsApp"
        default: rawValue.capitalized
        }
    }
}

enum NotificationLevel: String, Codable, CaseIterable, Identifiable, Sendable {
    case minimal, standard, persistent, off
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum PersonStatus: String, CaseIterable, Identifiable {
    case today, dueSoon, onTrack, drifting, neverContacted
    var id: String { rawValue }
    var title: String {
        switch self {
        case .today: "Due"
        case .dueSoon: "Due soon"
        case .onTrack: "On track"
        case .drifting: "Drifting"
        case .neverContacted: "Never contacted"
        }
    }
    var color: Color {
        switch self {
        case .today: .yellow
        case .dueSoon: .orange
        case .onTrack: .green
        case .drifting: .red
        case .neverContacted: .secondary
        }
    }
}
