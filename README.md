# StoreMesh iOS

Native iOS client foundation for StoreMesh.

## Stack

- Swift
- SwiftUI
- Swift concurrency (`async`/`await`)
- SwiftData for local client-side persistence when introduced
- BFF REST/JSON and GraphQL as the mobile-facing API boundary

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
layout. The client makes all mobile API requests to the BFF; it never calls
the internal gRPC services directly. The default simulator URL is:
`http://localhost:8080`.

## Backend and ngrok request flow

The request path for login and subsequent customer requests is:

```text
iOS app → HTTPS ngrok URL → StoreMesh BFF → internal gRPC services
                                      ├→ User Service (login/session)
                                      ├→ Product Service (catalog)
                                      └→ Order Service (commerce)
```

For a physical device, start the BFF as a local process and expose only that
process when a device cannot reach `localhost` directly:

```sh
ngrok http 8080
curl https://YOUR-NGROK-DOMAIN.ngrok-free.app/healthz
```

Configure the ngrok origin in Xcode with either a launch argument:

```text
-storemeshApiBaseURL https://YOUR-NGROK-DOMAIN.ngrok-free.app
```

or the `STOREMESH_API_BASE_URL` environment variable. The launch argument has
priority. Do not include `/api/v1` in the value; the client appends that path.
The default `localhost` value remains appropriate for a simulator when the
BFF is running directly on the development machine.

Keycloak migration uses Apple's `ASWebAuthenticationSession` with the
`storemesh-ios://oauth/callback` redirect and Authorization Code + PKCE. The
native authorization and token-exchange component is in
`StoreMesh/Features/Auth/OIDCAuth.swift`. The app will store resulting tokens
in Keychain and send access tokens as Bearer tokens to the BFF. The app should use HTTPS ngrok URLs only
for shared or physical-device testing, and ngrok authentication or a reserved
domain should be used before sharing a development endpoint. Never expose
gRPC, PostgreSQL, Redis, or observability ports through ngrok.

For testing on a physical device, start the local BFF and expose only port
8080 through an authenticated ngrok tunnel:

```sh
ngrok http 8080
```

Verify `https://YOUR-NGROK-DOMAIN.ngrok-free.app/healthz`, then use that HTTPS
origin as the app's API base URL. Keep tunnel URLs out of source control and
do not expose internal gRPC, database, Redis, or observability ports.

The native API client supports authenticated cart and order calls through the
BFF. The cart model is shared with native checkout work so cart state can be
synchronized across devices. The catalog now presents a native cart sheet
with quantity controls and clear-cart support. REST remains available for
compatibility. Docker and Kind are reserved for infrastructure and deployment
validation, not routine iOS feature development.

## Releases

Run the **iOS release** workflow manually. `semantic-release` determines the
next `MAJOR.MINOR.PATCH` from Conventional Commits, stamps
`MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`, creates the GitHub
release/tag, and builds the simulator target. Signing and App Store
distribution can be added later through protected GitHub Environment secrets.
## API transport

The app uses the Go BFF as its only API origin. Catalog and cart reads use the
authenticated GraphQL endpoint (`/api/v1/graphql`) for API composition; REST
now also handles cart updates, cart clearing, and idempotent order creation;
REST remains available for feature flags and compatibility operations.
GraphQL transport is isolated in `APIClient` so SwiftUI views do not own
request construction or response parsing.

The iOS CI workflow runs the unit and UI launch tests on a hosted iPhone
Simulator. Network-backed login and checkout scenarios remain a separate
environment test because they require a reachable BFF and Keycloak issuer.
