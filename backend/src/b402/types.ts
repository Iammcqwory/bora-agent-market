export type B402Method = 'eip3009' | 'permit2-exact' | 'permit2-upto';

export interface ResourceInfo {
  url: string;
  description?: string;
  mimeType?: string;
}

export interface Authorization {
  from: string;
  to: string;
  value: string;
  validAfter: string;
  validBefore: string;
  nonce: string;
}

export interface Permit2Authorization {
  permitted: { token: string; amount: string };
  from: string;
  spender: string;
  nonce: string;
  deadline: string;
  witness?: { to: string; facilitator: string; validAfter: string };
}

export interface PaymentPayload {
  x402Version: 2;
  accepted: {
    scheme: 'exact' | 'upto';
    network: string;
    asset: string;
    amount: string;
    payTo: string;
    maxTimeoutSeconds: number;
    extra?: Record<string, unknown>;
  };
  resource: ResourceInfo;
  payload: {
    signature: string;
    authorization?: Authorization;
    permit2Authorization?: Permit2Authorization;
  };
  extensions?: Record<string, unknown>;
}

export interface PaymentRequirements {
  scheme: 'exact' | 'upto';
  network: string;
  asset: string;
  amount: string;
  payTo: string;
  resource: ResourceInfo;
  maxTimeoutSeconds: number;
  extra: {
    assetTransferMethod: B402Method;
    signerAddress?: string;
    spenderAddress?: string;
    [key: string]: unknown;
  };
}

export interface B402Request {
  paymentPayload: PaymentPayload;
  paymentRequirements: PaymentRequirements;
}

export interface VerifyData {
  valid: boolean;
  payer?: string;
  reason?: string;
}

export interface SettleData {
  success: boolean;
  transaction: string;
  payer?: string;
  network?: string;
  amount?: string;
  errorReason?: string;
  errorMessage?: string;
}

export interface B402Envelope<T> {
  code: string;
  message: string;
  messageDetail?: string | null;
  data: T;
}
