# Binance B402 Alignment Notes

Verified 23 August 2026 against official Binance documentation.

## Confirmed requirements

- B402 agentic payments target BNB Smart Chain and support HTTP 402-style paid resources.
- BSC Testnet is available for external partner onboarding; BSC Mainnet production access is granted on request.
- Testnet and Production require separate developer applications and credentials.
- Partner onboarding asks for business name, email, EVM wallet address, API public key, IP whitelist, and optional webhook callback URL.
- Authenticated APIs use `/papi/v2/b402/*`; the V2 API is recommended for new integrations.
- Settlement is asynchronous: a broadcast transaction may return as pending and must be polled idempotently.
- B402 documentation states that HTTP status alone must not be used to determine settlement success; inspect the response data.
- B402 Bazaar discovery metadata is attached to V2 settlement and public discovery endpoints are distinct from authenticated payment APIs.
- B402 documentation warns that supported token decimals must be verified on chain; the changelog notes that BSC token decimals may differ from assumptions in examples.

## Repository implications

- Keep the existing physical-goods protocol separate from B402 paid agent services.
- Change the agent-service target network from Base to BSC Testnet in prototype configuration.
- Use USDC with `permit2-exact` as the first integration target, after verifying the current `/supported` response and token decimals.
- Add a backend adapter; do not expose B402 credentials in the React frontend.
- Model payment lifecycle as `challenged`, `verified`, `submitted`, `pending`, `settled`, `failed`, and `expired`.
- Build the prototype against B402 V2 wire shapes, not the legacy V1 examples.

## Official sources

- https://developers.binance.com/en/docs/products/onchainpay-x402/introduction
- https://developers.binance.com/legacy-docs/onchainpay-x402/basics/6.apply-developer-account
- https://developers.binance.com/en/docs/products/onchainpay-x402/change-log
- https://developers.binance.com/en/docs/products/onchainpay-x402/b402-bazaar
