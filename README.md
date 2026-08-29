# Connect

Connect is a private, local-first relationship and rapport companion for iOS 26. It turns a user's desired contact rhythms into a calm daily queue, keeps lightweight conversation context, and makes interaction logging fast.

The People tab includes both a searchable list and a tier board. On the board, drag a contact between columns to change their relationship tier, or use the card's Move menu for an accessible non-drag alternative.

## Requirements

- macOS with Xcode 26 or newer
- iOS 26 simulator or device
- An Apple Developer team for device builds, iCloud sync, notifications, and Contacts access

## Open and run

1. Open `Connect.xcodeproj` in Xcode.
2. Select the `Connect` target and choose your development team.
3. Change the bundle identifier and iCloud/App Group identifiers if the defaults are not available to your team.
4. Run the `Connect` scheme.

The app works offline. SwiftData is configured for private CloudKit sync when entitlements are available and falls back to a local store if CloudKit setup fails. Widget data is a privacy-minimized snapshot shared through the app group.

## GitHub IPA builds

The included GitHub Actions workflow runs the XCTest suite, validates both targets' profiles and capabilities, exports and verifies a signed IPA, generates a checksum, and optionally publishes a GitHub Release. Follow [GITHUB_IPA.md](GITHUB_IPA.md) to configure the Apple certificate, main-app and widget provisioning profiles, identifiers, and export method.

## Targets

- `Connect`: SwiftUI app, SwiftData persistence, Contacts, notifications, App Intents, export.
- `ConnectWidget`: small, medium, and lock-screen widgets.
- `ConnectTests`: deterministic scheduler, metrics, and tier-movement coverage.

## Privacy

Relationship content is not sent to third-party services. Notifications contain aggregate counts by default. Exports are created only after an explicit user action.

The public repository uses neutral fixtures and includes an automated identity/signing-material leak check. See [REPOSITORY_PRIVACY.md](REPOSITORY_PRIVACY.md).
