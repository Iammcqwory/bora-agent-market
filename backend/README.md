# Bora B402 Backend Adapter

This directory is the planned server-side integration boundary for Binance B402. The React application must not call authenticated B402 APIs directly because partner credentials, request signing, settlement retries, and payment reconciliation belong on the server.

## Initial target

The first implementation targets **BSC Testnet**, **B402 V2**, and **USDT with `permit2-exact`**. The token address and supported configurations must be loaded from Binance's authenticated `/supported` response after partner credentials are issued; they must not be guessed or copied from a Mainnet table.

## Responsibilities

The adapter will expose provider-neutral operations for `verify`, `settle`, and `getStatus`. It will normalize B402 responses into Bora payment states: `challenged`, `verified`, `submitted`, `pending`, `settled`, `failed`, and `expired`.

Settlement must be treated as asynchronous. A response containing a broadcast transaction hash can still be pending, even when the HTTP response is 200 or the nested `success` value is false. The reconciler must poll idempotently until the payment is settled or a terminal failure is recorded.

## Planned endpoints

| Endpoint | Purpose |
| --- | --- |
| `GET /api/services` | List published paid agent services. |
| `POST /api/payments/verify` | Validate an x402 V2 payment payload before settlement. |
| `POST /api/payments/settle` | Submit a verified payment to B402. |
| `GET /api/payments/:id` | Return normalized payment state and transaction receipt. |
| `POST /api/provider/402` | Optional provider helper for producing a standards-compliant payment challenge. |

## Environment

Copy `.env.example` to an environment-specific secret store. Never commit real credentials, private keys, or access tokens.

```bash
B402_ENVIRONMENT=testnet
B402_NETWORK=eip155:97
B402_API_VERSION=v2
B402_API_BASE_URL=
B402_CLIENT_ID=
B402_ACCESS_TOKEN=
B402_API_PRIVATE_KEY_PATH=
B402_WEBHOOK_PUBLIC_KEY=
B402_ALLOWED_ASSET=USDT
B402_ALLOWED_METHOD=permit2-exact
B402_ALLOWED_PAY_TO=
DATABASE_URL=
```

Production must use a separate Binance partner application and separate credentials. Mainnet activation should happen only after testnet integration, security review, and provider onboarding are complete.
