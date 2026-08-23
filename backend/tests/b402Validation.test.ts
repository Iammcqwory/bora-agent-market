import assert from 'node:assert/strict';
import test from 'node:test';
import {
  classifySettlement,
  isPaymentRequirementMatch,
  validatePaymentRequest,
} from '../src/b402/validation.ts';
import type { B402Envelope, B402Request, PaymentRequirements, SettleData } from '../src/b402/types.ts';

const payer = '0x1111111111111111111111111111111111111111';
const payTo = '0x2222222222222222222222222222222222222222';
const asset = '0x3333333333333333333333333333333333333333';
const signature = `0x${'ab'.repeat(65)}`;
const resourceUrl = 'https://api.bora.test/v1/authenticity';

function requirements(overrides: Partial<PaymentRequirements> = {}): PaymentRequirements {
  return {
    scheme: 'exact',
    network: 'eip155:97',
    asset,
    amount: '100000000000000000',
    payTo,
    resource: { url: resourceUrl, description: 'Authenticity report', mimeType: 'application/json' },
    maxTimeoutSeconds: 300,
    extra: { assetTransferMethod: 'permit2-exact' },
    ...overrides,
  };
}

function request(overrides: Partial<B402Request> = {}): B402Request {
  const paymentRequirements = requirements();
  return {
    paymentRequirements,
    paymentPayload: {
      x402Version: 2,
      accepted: {
        scheme: paymentRequirements.scheme,
        network: paymentRequirements.network,
        asset: paymentRequirements.asset,
        amount: paymentRequirements.amount,
        payTo: paymentRequirements.payTo,
        maxTimeoutSeconds: paymentRequirements.maxTimeoutSeconds,
      },
      resource: paymentRequirements.resource,
      payload: {
        signature,
        permit2Authorization: {
          permitted: { token: asset, amount: paymentRequirements.amount },
          from: payer,
          spender: '0x4444444444444444444444444444444444444444',
          nonce: '7',
          deadline: '1700000300',
        },
      },
    },
    ...overrides,
  };
}

const policy = {
  network: 'eip155:97',
  asset,
  method: 'permit2-exact',
  payTo,
  resourceUrl,
  now: 1700000000,
};

function settlement(data: Partial<SettleData>): B402Envelope<SettleData> {
  return { code: '000000', message: 'success', data: { success: false, transaction: '', ...data } };
}

test('accepts a valid B402 V2 permit2-exact request', () => {
  const result = validatePaymentRequest(request(), policy);
  assert.equal(result.valid, true);
  assert.deepEqual(result.issues, []);
});

test('matches payment requirements case-insensitively for addresses', () => {
  const input = request();
  input.paymentPayload.accepted.asset = asset.toUpperCase();
  input.paymentPayload.accepted.payTo = payTo.toUpperCase();
  assert.equal(isPaymentRequirementMatch(input.paymentPayload, input.paymentRequirements), true);
});

test('rejects a non-V2 payload', () => {
  const input = request();
  input.paymentPayload.x402Version = 1 as 2;
  const result = validatePaymentRequest(input, policy);
  assert.ok(result.issues.some((issue) => issue.code === 'invalid_version'));
});

test('rejects a wrong network in either accepted payload or requirements', () => {
  const input = request();
  input.paymentRequirements.network = 'eip155:56';
  const result = validatePaymentRequest(input, policy);
  assert.ok(result.issues.some((issue) => issue.code === 'invalid_network'));
});

test('rejects an asset outside the service allowlist', () => {
  const input = request();
  input.paymentPayload.accepted.asset = '0x5555555555555555555555555555555555555555';
  const result = validatePaymentRequest(input, policy);
  assert.ok(result.issues.some((issue) => issue.code === 'invalid_asset'));
});

test('rejects a payment method that is not permit2-exact', () => {
  const input = request();
  input.paymentRequirements.extra.assetTransferMethod = 'permit2-upto';
  const result = validatePaymentRequest(input, policy);
  assert.ok(result.issues.some((issue) => issue.code === 'invalid_method'));
});

test('rejects mismatched schemes and amounts', () => {
  const input = request();
  input.paymentPayload.accepted.scheme = 'upto';
  input.paymentPayload.accepted.amount = '1';
  const result = validatePaymentRequest(input, policy);
  assert.ok(result.issues.some((issue) => issue.code === 'invalid_scheme'));
  assert.ok(result.issues.some((issue) => issue.code === 'invalid_amount'));
});

test('rejects malformed or non-positive amount strings', () => {
  const input = request();
  input.paymentRequirements.amount = 'not-a-number';
  input.paymentPayload.accepted.amount = 'not-a-number';
  const result = validatePaymentRequest(input, policy);
  assert.ok(result.issues.some((issue) => issue.code === 'invalid_amount'));
});

test('rejects an unapproved recipient and malformed EVM address', () => {
  const input = request();
  input.paymentRequirements.payTo = '0x1234';
  input.paymentPayload.accepted.payTo = '0x1234';
  const result = validatePaymentRequest(input, policy);
  assert.ok(result.issues.some((issue) => issue.code === 'invalid_recipient'));
});

test('rejects a resource mismatch to prevent payment replay across endpoints', () => {
  const input = request();
  input.paymentPayload.resource.url = 'https://api.bora.test/v1/other-resource';
  const result = validatePaymentRequest(input, policy);
  assert.ok(result.issues.some((issue) => issue.code === 'invalid_resource'));
});

test('rejects missing and malformed signatures', () => {
  const missing = request();
  missing.paymentPayload.payload.signature = '';
  const missingResult = validatePaymentRequest(missing, policy);
  assert.ok(missingResult.issues.some((issue) => issue.code === 'missing_signature'));

  const malformed = request();
  malformed.paymentPayload.payload.signature = '0x1234';
  const malformedResult = validatePaymentRequest(malformed, policy);
  assert.ok(malformedResult.issues.some((issue) => issue.code === 'missing_signature'));
});

test('rejects an expired permit2 deadline', () => {
  const input = request();
  input.paymentPayload.payload.permit2Authorization!.deadline = '1699999999';
  const result = validatePaymentRequest(input, policy);
  assert.ok(result.issues.some((issue) => issue.code === 'authorization_expired'));
});

test('rejects an authorization that is not active yet', () => {
  const input = request();
  input.paymentPayload.payload.permit2Authorization!.witness = {
    to: payTo,
    facilitator: payTo,
    validAfter: '1700000001',
  };
  const result = validatePaymentRequest(input, policy);
  assert.ok(result.issues.some((issue) => issue.code === 'authorization_not_yet_valid'));
});

test('rejects a request with no authorization object', () => {
  const input = request();
  input.paymentPayload.payload = { signature };
  const result = validatePaymentRequest(input, policy);
  assert.ok(result.issues.some((issue) => issue.code === 'missing_authorization'));
});

test('classifies an immediate successful settlement as terminal', () => {
  const result = classifySettlement(settlement({ success: true, transaction: '0xsettled' }));
  assert.deepEqual(result, { state: 'settled', terminal: true, transaction: '0xsettled' });
});

test('classifies a broadcast response with no error as pending', () => {
  const result = classifySettlement(settlement({ transaction: '0xpending' }));
  assert.deepEqual(result, { state: 'pending', terminal: false, transaction: '0xpending', reason: undefined });
});

test('classifies a confirmation timeout with a transaction as pending', () => {
  const result = classifySettlement(settlement({ transaction: '0xtimeout', errorReason: 'settle_exact_evm_transaction_confirmation_timed_out' }));
  assert.equal(result.state, 'pending');
  assert.equal(result.terminal, false);
});

test('classifies a confirmation timeout without a transaction as terminal failure', () => {
  const result = classifySettlement(settlement({ errorReason: 'settle_exact_evm_transaction_confirmation_timed_out' }));
  assert.equal(result.state, 'failed');
  assert.equal(result.terminal, true);
});

test('classifies an on-chain revert as terminal failure', () => {
  const result = classifySettlement(settlement({ transaction: '0xreverted', errorReason: 'settle_exact_failed_onchain' }));
  assert.deepEqual(result, { state: 'failed', terminal: true, transaction: '0xreverted', reason: 'settle_exact_failed_onchain' });
});
