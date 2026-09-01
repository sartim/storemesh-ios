# StoreMesh iOS

Native iOS client foundation for StoreMesh.

## Stack

- Swift
- SwiftUI
- Swift concurrency (`async`/`await`)
- SwiftData for local client-side persistence when introduced
- BFF REST/JSON as the mobile-facing API boundary

No cross-platform UI framework is used. The iOS app will follow Apple’s native
SwiftUI navigation, accessibility, previews, and adaptive layout patterns.

## Structure

```text
StoreMesh/
├── App/              # App entry point and dependency container
├── Core/             # API client, auth, models, and shared UI
├── Features/
│   ├── Auth/         # Login and session state
│   ├── Catalog/      # Customer catalog and product details
│   ├── Checkout/     # Cart and order creation
│   ├── Orders/       # Customer order history
│   └── Admin/        # Role-aware operations UI
└── Resources/        # Assets, localization, and configuration
```

Create or open the native iOS app target in Xcode using the `StoreMesh` source
layout. Local development points at the BFF port-forward:
`http://localhost:8080/api/v1`.

## Releases

Run the **iOS release** workflow manually. `semantic-release` determines the
next `MAJOR.MINOR.PATCH` from Conventional Commits, stamps
`MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`, creates the GitHub
release/tag, and builds the simulator target. Signing and App Store
distribution can be added later through protected GitHub Environment secrets.
