import type { B402Request, B402Envelope, PaymentRequirements, SettleData } from './types.ts';

export interface ValidationPolicy {
  network: string;
  asset: string;
  method: string;
  payTo?: string;
  resourceUrl?: string;
  now?: number;
}

export type ValidationCode =
  | 'invalid_version'
  | 'invalid_network'
  | 'invalid_asset'
  | 'invalid_method'
  | 'invalid_scheme'
  | 'invalid_amount'
  | 'invalid_recipient'
  | 'invalid_resource'
  | 'authorization_expired'
  | 'authorization_not_yet_valid'
  | 'missing_signature'
  | 'missing_authorization';

export interface ValidationIssue {
  code: ValidationCode;
  message: string;
}

export interface ValidationResult {
  valid: boolean;
  issues: ValidationIssue[];
}

const ADDRESS_PATTERN = /^0x[a-fA-F0-9]{40}$/;
const SIGNATURE_PATTERN = /^0x[a-fA-F0-9]{130}$/;

function asPositiveInteger(value: string): boolean {
  try {
    return BigInt(value) > 0n;
  } catch {
    return false;
  }
}

function addIssue(issues: ValidationIssue[], code: ValidationCode, message: string) {
  issues.push({ code, message });
}

export function validatePaymentRequest(request: B402Request, policy: ValidationPolicy): ValidationResult {
  const issues: ValidationIssue[] = [];
  const { paymentPayload: payload, paymentRequirements: requirements } = request;
  const now = policy.now ?? Math.floor(Date.now() / 1000);

  if (payload.x402Version !== 2) addIssue(issues, 'invalid_version', 'Only x402 V2 payloads are accepted.');
  if (requirements.network !== policy.network || payload.accepted.network !== policy.network) {
    addIssue(issues, 'invalid_network', `Payment network must be ${policy.network}.`);
  }
  if (requirements.asset.toLowerCase() !== policy.asset.toLowerCase() || payload.accepted.asset.toLowerCase() !== policy.asset.toLowerCase()) {
    addIssue(issues, 'invalid_asset', 'Payment asset is not allowed by this service.');
  }
  if (requirements.extra.assetTransferMethod !== policy.method) {
    addIssue(issues, 'invalid_method', `Payment method must be ${policy.method}.`);
  }
  if (!['exact', 'upto'].includes(requirements.scheme) || requirements.scheme !== payload.accepted.scheme) {
    addIssue(issues, 'invalid_scheme', 'Payment schemes must be supported and must match.');
  }
  if (!asPositiveInteger(requirements.amount) || requirements.amount !== payload.accepted.amount) {
    addIssue(issues, 'invalid_amount', 'Payment amount must be a matching positive integer string.');
  }
  if (!ADDRESS_PATTERN.test(requirements.payTo) || requirements.payTo.toLowerCase() !== (policy.payTo ?? requirements.payTo).toLowerCase()) {
    addIssue(issues, 'invalid_recipient', 'Payment recipient is not an allowed EVM address.');
  }
  if (!payload.resource.url || payload.resource.url !== requirements.resource.url || (policy.resourceUrl && payload.resource.url !== policy.resourceUrl)) {
    addIssue(issues, 'invalid_resource', 'Payment resource does not match the requested endpoint.');
  }
  if (!SIGNATURE_PATTERN.test(payload.payload.signature)) addIssue(issues, 'missing_signature', 'A valid 65-byte hex signature is required.');

  const authorization = payload.payload.authorization ?? payload.payload.permit2Authorization;
  if (!authorization) {
    addIssue(issues, 'missing_authorization', 'An authorization object is required.');
  } else {
    const validAfter = Number('validAfter' in authorization
      ? authorization.validAfter
      : (authorization.witness?.validAfter ?? 0));
    const validBefore = Number('validBefore' in authorization ? authorization.validBefore : authorization.deadline);
    if (!Number.isFinite(validBefore) || validBefore <= now) addIssue(issues, 'authorization_expired', 'Payment authorization is expired.');
    if (!Number.isFinite(validAfter) || validAfter > now) addIssue(issues, 'authorization_not_yet_valid', 'Payment authorization is not active yet.');
  }

  return { valid: issues.length === 0, issues };
}

export function isPaymentRequirementMatch(payload: B402Request['paymentPayload'], requirements: PaymentRequirements): boolean {
  return payload.accepted.network === requirements.network
    && payload.accepted.asset.toLowerCase() === requirements.asset.toLowerCase()
    && payload.accepted.amount === requirements.amount
    && payload.accepted.payTo.toLowerCase() === requirements.payTo.toLowerCase()
    && payload.resource.url === requirements.resource.url;
}

export type SettlementState = 'settled' | 'pending' | 'failed';

export interface SettlementClassification {
  state: SettlementState;
  terminal: boolean;
  transaction: string;
  reason?: string;
}

export function classifySettlement(envelope: B402Envelope<SettleData>): SettlementClassification {
  const data = envelope.data;
  const transaction = data.transaction ?? '';
  const timeout = data.errorReason === 'settle_exact_evm_transaction_confirmation_timed_out';

  if (data.success) return { state: 'settled', terminal: true, transaction };
  if (transaction && (!data.errorReason || timeout)) {
    return { state: 'pending', terminal: false, transaction, reason: data.errorReason };
  }
  return { state: 'failed', terminal: true, transaction, reason: data.errorReason ?? data.errorMessage ?? 'settlement_failed' };
}
