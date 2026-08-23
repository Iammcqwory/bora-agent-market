export const B402_CONFIG = {
  environment: 'testnet',
  chainId: 97,
  caip2Network: 'eip155:97',
  networkLabel: 'BNB Smart Chain Testnet',
  apiVersion: 'v2',
  authenticatedApiBase: '',
  discoveryBase: '',
  // BSC Testnet asset details must be confirmed from the partner /supported response.
  // Keep the address empty until Binance credentials and the live configuration are available.
  initialAsset: {
    symbol: 'USDT',
    address: '',
    decimals: 18,
    methods: ['permit2-exact'] as const,
  },
  supportedAssets: [
    { symbol: 'USDC', methods: ['permit2-exact', 'permit2-upto'] },
    { symbol: 'USDT', methods: ['permit2-exact', 'permit2-upto'] },
    { symbol: 'USD1', methods: ['eip3009', 'permit2-exact', 'permit2-upto'] },
    { symbol: 'U', methods: ['eip3009', 'permit2-exact', 'permit2-upto'] },
  ],
} as const;

export type B402PaymentState =
  | 'challenged'
  | 'verified'
  | 'submitted'
  | 'pending'
  | 'settled'
  | 'failed'
  | 'expired';

export const B402_PAYMENT_STATES: Array<{ state: B402PaymentState; label: string }> = [
  { state: 'challenged', label: 'Payment requested' },
  { state: 'verified', label: 'Authorization verified' },
  { state: 'submitted', label: 'Settlement submitted' },
  { state: 'pending', label: 'Awaiting confirmation' },
  { state: 'settled', label: 'Payment settled' },
];
