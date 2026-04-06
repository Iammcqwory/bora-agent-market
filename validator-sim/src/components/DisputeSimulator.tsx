import { useState } from 'react';
import {
  CONNECTED_VALIDATOR_LABEL,
  getCurrentValidatorListings,
} from '../lib/validatorSimulation';
import type { Listing } from '../data/mockListings';
import type { DisputeOutcome } from '../lib/validatorSimulation';

interface DisputeSimulatorProps {
  stakedListings: Listing[];
  onDispute: (listingId: string, outcome: DisputeOutcome) => void;
}

const SIMULATED_RESOLUTION_DELAY_MS = 2000;

export function DisputeSimulator({ stakedListings, onDispute }: DisputeSimulatorProps) {
  const [selectedListingId, setSelectedListingId] = useState<string>();
  const [isSimulating, setIsSimulating] = useState(false);

  const userStakedListings = getCurrentValidatorListings(
    stakedListings,
    CONNECTED_VALIDATOR_LABEL,
  );

  const simulateDispute = async (outcome: DisputeOutcome) => {
    if (!selectedListingId) {
      return;
    }

    setIsSimulating(true);
    await new Promise((resolve) => setTimeout(resolve, SIMULATED_RESOLUTION_DELAY_MS));
    onDispute(selectedListingId, outcome);
    setSelectedListingId(undefined);
    setIsSimulating(false);
  };

  if (userStakedListings.length === 0) {
    return (
      <div className="panel min-h-[18rem]">
        <p className="section-label">Dispute Test</p>
        <h3 className="mt-3 text-2xl font-semibold">Nothing to test yet.</h3>
        <p className="mt-3 max-w-md text-sm leading-7 text-white/68">
          Take at least one validation job from the listings section, then come back here to see
          how a buyer win or validator win affects the result.
        </p>
      </div>
    );
  }

  return (
    <section className="panel min-h-[18rem]">
      <p className="section-label">Dispute Test</p>
      <h3 className="mt-3 text-2xl font-semibold">Test what happens when a buyer challenges your validation.</h3>

      <p className="mt-3 max-w-lg text-sm leading-7 text-white/68">
        Pick one of your active positions, then choose an outcome. Buyer wins means your stake is
        slashed. Validator wins means you keep the stake and convert the position into earnings.
      </p>

      <div className="mt-6 space-y-4">
        <div>
          <label className="mb-2 block text-sm font-medium text-white/78">Active position</label>
          <select
            value={selectedListingId ?? ''}
            onChange={(event) => setSelectedListingId(event.target.value || undefined)}
            className="w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 py-3 text-white"
            disabled={isSimulating}
          >
            <option value="">Choose a listing...</option>
            {userStakedListings.map((listing) => (
              <option key={listing.id} value={listing.id}>
                {listing.title} | ${listing.stakeRequired} stake at risk
              </option>
            ))}
          </select>
        </div>

        <div className="grid gap-3 sm:grid-cols-2">
          <button
            onClick={() => simulateDispute('buyer_wins')}
            disabled={isSimulating || !selectedListingId}
            className="rounded-full border border-red-500/50 bg-red-500/18 px-4 py-3 text-sm font-semibold text-red-400 transition hover:bg-red-500/26 disabled:opacity-50"
          >
            {isSimulating ? 'Resolving...' : 'Buyer wins dispute'}
          </button>
          <button
            onClick={() => simulateDispute('validator_wins')}
            disabled={isSimulating || !selectedListingId}
            className="rounded-full border border-bora-green/50 bg-bora-green/18 px-4 py-3 text-sm font-semibold text-bora-green transition hover:bg-bora-green/26 disabled:opacity-50"
          >
            {isSimulating ? 'Resolving...' : 'Validator wins dispute'}
          </button>
        </div>

        <div className="rounded-2xl border border-white/10 bg-white/[0.03] p-4 text-sm text-white/58">
          In production, Bora plans to route disputes through AI review, community jury, and a
          final council layer. This panel is a fast way to test the economic outcomes.
        </div>
      </div>
    </section>
  );
}
