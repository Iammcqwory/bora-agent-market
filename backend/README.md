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

## Configure Binance B402 Testnet access

B402 Testnet and Production use separate partner applications and separate credentials. Start with the Binance B402 partner application at [Apply partner developer account](https://forms.gle/aUQvxUETfGMzyTky5). Select the Testnet/Sandbox environment and provide Bora's business or brand name, integration email, EVM wallet address for receiving testnet funds, API public key, outbound IP addresses for whitelisting, and an optional webhook callback URL. Binance provides the Testnet `clientId`, access token, and webhook verification public key after onboarding.

Generate an API key pair locally and keep the private key on the backend host. For example:

```bash
mkdir -p backend/secrets
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out backend/secrets/b402-testnet-private.pem
openssl rsa -in backend/secrets/b402-testnet-private.pem -pubout -out backend/secrets/b402-testnet-public.pem
chmod 600 backend/secrets/b402-testnet-private.pem
```

Submit the public key to Binance, add the backend's stable outbound IP address to the whitelist, and store the returned `clientId` and access token in the deployment secret manager. Do not put either credential in Vite environment variables, browser code, Git history, screenshots, or issue comments. The authenticated B402 base URL is issued or confirmed during partner onboarding; leave `B402_API_BASE_URL` empty until Binance provides it.

Copy `.env.example` to an environment-specific secret store. Never commit real credentials, private keys, access tokens, or the generated `backend/secrets` directory.

```bash
cp backend/.env.example backend/.env.testnet
# Fill the file only in a local ignored environment or secret manager.
```

For the first testnet flow, use `eip155:97`, query the live B402 V2 `/supported` configuration, and confirm the testnet token address and decimals from that response. Do not copy a BSC Mainnet token address into the Testnet configuration.


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

## Test commands

The deterministic validation suite requires no Binance credentials and is safe to run in CI:

```bash
cd backend
npm test
```

It covers valid V2 requests, network and asset allowlists, recipient and resource binding, payment-method mismatches, amount and scheme mismatches, signature shape, missing authorizations, authorization timing, and the B402 pending-versus-terminal settlement rules. It deliberately mocks facilitator responses instead of moving funds.

A live payment test should be run manually or in a protected integration environment only after Binance issues Testnet credentials and a real test wallet has been funded. The live harness must use a disposable wallet, a tiny test amount, the authenticated B402 V2 base URL, and a provider endpoint that returns a real 402 challenge. Never run it automatically in public CI and never use a production wallet for testing.

Production must use a separate Binance partner application and separate credentials. Mainnet activation should happen only after testnet integration, security review, provider onboarding, and an explicit decision about supported assets and settlement policies.
