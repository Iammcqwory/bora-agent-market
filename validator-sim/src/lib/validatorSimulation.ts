import type { Listing } from '../data/mockListings';

export const CONNECTED_VALIDATOR_LABEL = 'YOU';
export const MOCK_USER_ADDRESS = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';

const COMMISSION_RATE = 0.01;
const ESTIMATED_ANNUAL_VALIDATIONS = 22;

export type DisputeOutcome = 'buyer_wins' | 'validator_wins';

export interface ValidatorResults {
  completedValidations: number;
  realizedCommissions: number;
  lostDisputes: number;
}

export interface ValidatorStats extends ValidatorResults {
  totalStaked: number;
  activeStakes: number;
  projectedCommissions: number;
  currentAPY: number;
}

export function getListingCommission(price: number) {
  return price * COMMISSION_RATE;
}

export function isListingManagedByCurrentValidator(
  listing: Listing,
  validatorLabel = CONNECTED_VALIDATOR_LABEL,
) {
  return listing.validator === validatorLabel;
}

export function getCurrentValidatorListings(
  listings: Listing[],
  validatorLabel = CONNECTED_VALIDATOR_LABEL,
) {
  return listings.filter(
    (listing) => listing.isStaked && isListingManagedByCurrentValidator(listing, validatorLabel),
  );
}

export function buildValidatorStats(
  listings: Listing[],
  results: ValidatorResults,
  validatorLabel = CONNECTED_VALIDATOR_LABEL,
): ValidatorStats {
  const activeListings = getCurrentValidatorListings(listings, validatorLabel);
  const totalStaked = activeListings.reduce((sum, listing) => sum + listing.stakeRequired, 0);
  const projectedCommissions = activeListings.reduce(
    (sum, listing) => sum + getListingCommission(listing.price),
    0,
  );

  const currentAPY =
    totalStaked > 0
      ? (projectedCommissions / totalStaked) * ESTIMATED_ANNUAL_VALIDATIONS * 100
      : 0;

  return {
    totalStaked,
    activeStakes: activeListings.length,
    projectedCommissions,
    currentAPY,
    ...results,
  };
}
