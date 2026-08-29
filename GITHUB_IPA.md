# Build iPhone IPAs with GitHub Actions

The workflow in `.github/workflows/ios.yml` uses GitHub's `macos-26` runner, prefers Xcode 26.6, and safely falls back to another installed Xcode 26 release.

Every push, pull request, tag, and manual build runs the XCTest suite on a temporary iPhone simulator.

Every push to `main` or `master`, every version tag, and every manual run also compiles the device target without signing and uploads:

- `Connect-v<version>-unsigned-r<run>.ipa`
- its SHA-256 checksum

This unsigned artifact requires no Apple certificate, provisioning profile, developer-team identifier, or GitHub secret. Download it from the workflow run's **Artifacts** section.

An optional signed IPA is generated when you:

- run **Actions → iOS 26 Build → Run workflow** and enable `build_signed`, or
- push a version tag such as `v1.0.0`.

The resulting IPA and its SHA-256 checksum appear under **Artifacts** on the workflow run. For a manual build, enable `publish_release` only when you explicitly want a direct GitHub Release download. Tagged builds remain workflow artifacts by default because Development and Ad Hoc profiles embed registered device identifiers that should not be published casually.

The unsigned IPA follows the same packaging approach as common sideloading workflows: it is a zip containing `Payload/Connect.app`, including the widget extension. It verifies and distributes the compiled device bundle, but it is not Apple-signed and therefore cannot be installed directly on a stock iPhone without a separate signing or sideloading step.

## 1. Register identifiers in Apple Developer

Create these explicit identifiers:

- Main app: for example `com.example.connect`
- Widget: the main identifier plus `.widget`
- iCloud container: for example `iCloud.com.example.connect`
- App Group: for example `group.com.example.connect`

Enable **iCloud/CloudKit** and **App Groups** for the main app. Enable the same **App Group** for the widget.

## 2. Create signing material

Create or export a `.p12` certificate appropriate for the export method, then create two provisioning profiles:

- one for the main app identifier;
- one for the widget identifier.

Both profiles must include their required capabilities. Use development profiles for a development IPA, Ad Hoc profiles for device distribution, or App Store profiles for App Store Connect.

## 3. Configure repository variables

In **Repository Settings → Secrets and variables → Actions → Variables**, add:

| Variable | Example |
| --- | --- |
| `APPLE_TEAM_ID` | `A1B2C3D4E5` |
| `IOS_BUNDLE_ID` | `com.example.connect` |
| `IOS_ICLOUD_CONTAINER_ID` | `iCloud.com.example.connect` |
| `IOS_APP_GROUP_ID` | `group.com.example.connect` |
| `IOS_EXPORT_METHOD` | Default for version tags: `development`, `ad-hoc`, or `app-store-connect` |

Manual runs select the export method from a validated dropdown and override `IOS_EXPORT_METHOD` for that run.

## 4. Configure the signing environment and encrypted secrets

Create a GitHub Environment named `ios-signing`. If your GitHub plan supports deployment protection rules, add a required reviewer so a compromised branch cannot immediately use signing material. Add these as **environment secrets** (repository Actions secrets also work, but have a wider scope):

| Secret | Value |
| --- | --- |
| `IOS_CERTIFICATE_BASE64` | Base64 contents of the `.p12` file |
| `IOS_CERTIFICATE_PASSWORD` | Password used when exporting the `.p12` |
| `IOS_APP_PROFILE_BASE64` | Base64 contents of the main-app profile |
| `IOS_WIDGET_PROFILE_BASE64` | Base64 contents of the widget profile |
| `IOS_KEYCHAIN_PASSWORD` | A new random password used only by the temporary CI keychain |

PowerShell can encode each binary file without changing it:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes('certificate.p12'))
[Convert]::ToBase64String([IO.File]::ReadAllBytes('Connect.mobileprovision'))
[Convert]::ToBase64String([IO.File]::ReadAllBytes('ConnectWidget.mobileprovision'))
```

Paste each command's output into its matching GitHub secret. Never commit certificates, profiles, passwords, or Base64 signing values to the repository.

Before importing the certificate, CI validates that both profiles:

- are unexpired and belong to `APPLE_TEAM_ID`;
- match the main app and widget bundle identifiers;
- match the selected Development, Ad Hoc, or App Store distribution method;
- contain the required App Group, and that the app profile contains the iCloud container.

The signing job also checks the exported code signature, verifies that the widget is embedded, names the IPA from the archived app version, and generates a SHA-256 checksum.

All third-party GitHub Actions are pinned to immutable commit SHAs. Dependabot checks them weekly and proposes grouped updates in `.github/dependabot.yml`.

## Installation notes

- A `development` IPA installs only on devices included in the development profile.
- An `ad-hoc` IPA installs only on devices whose UDIDs are included in the Ad Hoc profile.
- An `app-store-connect` IPA is intended for upload to App Store Connect/TestFlight, not direct installation.
- A truly installable IPA must be signed. Renaming or zipping an unsigned `.app` does not create a valid installable IPA.
