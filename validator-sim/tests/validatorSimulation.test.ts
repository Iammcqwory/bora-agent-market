import assert from 'node:assert/strict';
import test from 'node:test';
import {
  buildValidatorStats,
  CONNECTED_VALIDATOR_LABEL,
  getCurrentValidatorListings,
  getListingCommission,
} from '../src/lib/validatorSimulation.ts';
import type { Listing } from '../src/data/mockListings.ts';
import type { ValidatorResults } from '../src/lib/validatorSimulation.ts';

const baseResults: ValidatorResults = {
  completedValidations: 0,
  realizedCommissions: 0,
  lostDisputes: 0,
};

const listings: Listing[] = [
  {
    id: 'managed',
    title: 'Managed item',
    price: 1000,
    seller: '0x1111111111111111111111111111111111111111',
    category: 'camera',
    imageUrl: 'managed.jpg',
    description: 'A listing managed by the connected validator.',
    condition: 'Excellent',
    stakeRequired: 350,
    isStaked: true,
    validator: CONNECTED_VALIDATOR_LABEL,
  },
  {
    id: 'other-validator',
    title: 'Other validator item',
    price: 500,
    seller: '0x2222222222222222222222222222222222222222',
    category: 'lens',
    imageUrl: 'other.jpg',
    description: 'A listing managed by another validator.',
    condition: 'Good',
    stakeRequired: 175,
    isStaked: true,
    validator: 'MARA-Validator-01',
  },
  {
    id: 'open',
    title: 'Open item',
    price: 200,
    seller: '0x3333333333333333333333333333333333333333',
    category: 'audio',
    imageUrl: 'open.jpg',
    description: 'A listing that has not been staked yet.',
    condition: 'Very Good',
    stakeRequired: 70,
    isStaked: false,
  },
];

test('calculates listing commission at one percent', () => {
  assert.equal(getListingCommission(1000), 10);
  assert.equal(getListingCommission(85), 0.85);
});

test('filters active listings to the connected validator', () => {
  const managedListings = getCurrentValidatorListings(listings);

  assert.equal(managedListings.length, 1);
  assert.equal(managedListings[0]?.id, 'managed');
});

test('builds validator stats from active managed listings and prior results', () => {
  const stats = buildValidatorStats(listings, {
    completedValidations: 2,
    realizedCommissions: 15,
    lostDisputes: 1,
  });

  assert.equal(stats.totalStaked, 350);
  assert.equal(stats.activeStakes, 1);
  assert.equal(stats.projectedCommissions, 10);
  assert.equal(stats.currentAPY, (10 / 350) * 22 * 100);
  assert.equal(stats.completedValidations, 2);
  assert.equal(stats.realizedCommissions, 15);
  assert.equal(stats.lostDisputes, 1);
});

test('returns zero exposure and APY when no current-validator stakes exist', () => {
  const stats = buildValidatorStats(
    listings.map((listing) =>
      listing.validator === CONNECTED_VALIDATOR_LABEL
        ? { ...listing, isStaked: false, validator: undefined }
        : listing,
    ),
    baseResults,
  );

  assert.equal(stats.totalStaked, 0);
  assert.equal(stats.activeStakes, 0);
  assert.equal(stats.projectedCommissions, 0);
  assert.equal(stats.currentAPY, 0);
});
