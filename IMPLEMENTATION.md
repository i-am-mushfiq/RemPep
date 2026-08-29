# Connect implementation map

## Product loop

| PRD system | Implementation |
| --- | --- |
| People | SwiftData `Person` profiles, tier/frequency editing, drag-and-drop tier board, archive/restore, search/filter/sort, manual and Contacts bulk import |
| Scheduler | Pure deterministic `SchedulingEngine`, urgency/overdue/tier scoring, capped overdue pressure, tier-balanced queue, recovery rebalancing |
| Context | Approved memories with category/lifespan/expiration, notes, important dates, interaction history |
| Rapport | Deterministic private prompts from stored context, four conversation modes, occasional tips, no external AI |
| Progress | Daily ring, weekly summary, 14-day chart, meaningful count, relationship coverage |

## Platform integrations

- SwiftData local-first storage with private CloudKit configuration and offline fallback
- Contacts permission requested only from import flows
- Aggregate notification levels plus opt-in important-date reminders
- Messages and Phone deep links with return-to-log flow
- Small, medium, circular, and rectangular WidgetKit widgets
- App Intents for opening Today, logging a connection, and finding ready people
- JSON and flattened CSV full-data export
- App Group widget snapshot and privacy manifests

## Validation

The project includes 21 XCTest cases, including every scheduler scenario listed in PRD section 92 and cadence-preserving tier-movement coverage. On a Mac with Xcode 26, run:

```sh
xcodebuild -project Connect.xcodeproj -scheme Connect -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

Device and archive builds require replacing the placeholder bundle, CloudKit container, and App Group identifiers with identifiers owned by the selected Apple Developer team.
