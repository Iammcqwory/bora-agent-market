import { useState } from 'react';
import heroImage from './assets/hero.png';
import { DisputeSimulator } from './components/DisputeSimulator';
import { ListingCard } from './components/ListingCard';
import { ToastContainer } from './components/ToastNotification';
import { ValidatorDashboard } from './components/ValidatorDashboard';
import { mockListings } from './data/mockListings';
import {
  buildValidatorStats,
  CONNECTED_VALIDATOR_LABEL,
  getListingCommission,
  MOCK_USER_ADDRESS,
} from './lib/validatorSimulation';
import type { Toast } from './components/ToastNotification';
import type { Listing } from './data/mockListings';
import type { DisputeOutcome, ValidatorResults } from './lib/validatorSimulation';

const SIMULATED_WALLET_DELAY_MS = 1000;

const initialResults: ValidatorResults = {
  completedValidations: 0,
  realizedCommissions: 0,
  lostDisputes: 0,
};

function App() {
  const [listings, setListings] = useState<Listing[]>(mockListings);
  const [userAddress, setUserAddress] = useState<string>();
  const [isConnecting, setIsConnecting] = useState(false);
  const [toasts, setToasts] = useState<Toast[]>([]);
  const [results, setResults] = useState<ValidatorResults>(initialResults);

  const validatorStats = buildValidatorStats(listings, results);
  const activeListings = listings.filter((listing) => listing.isStaked);
  const availableListings = listings.filter((listing) => !listing.isStaked);
  const protocolYieldSignal = validatorStats.currentAPY > 0 ? validatorStats.currentAPY : 32.4;

  const addToast = (message: string, type: Toast['type']) => {
    setToasts((currentToasts) => [
      ...currentToasts,
      { id: Date.now().toString(), message, type },
    ]);
  };

  const dismissToast = (id: string) => {
    setToasts((currentToasts) => currentToasts.filter((toast) => toast.id !== id));
  };

  const connectWallet = async () => {
    setIsConnecting(true);
    await new Promise((resolve) => setTimeout(resolve, SIMULATED_WALLET_DELAY_MS));
    setUserAddress(MOCK_USER_ADDRESS);
    setIsConnecting(false);
  };

  const updateListing = (listingId: string, updater: (listing: Listing) => Listing) => {
    setListings((currentListings) =>
      currentListings.map((listing) => (listing.id === listingId ? updater(listing) : listing)),
    );
  };

  const handleStake = (listingId: string) => {
    const listing = listings.find((entry) => entry.id === listingId);
    if (!listing) {
      return;
    }

    updateListing(listingId, (currentListing) => ({
      ...currentListing,
      isStaked: true,
      validator: CONNECTED_VALIDATOR_LABEL,
    }));

    addToast(
      `You staked $${listing.stakeRequired} on ${listing.title}. Projected commission: $${getListingCommission(listing.price).toFixed(2)}.`,
      'success',
    );
  };

  const handleUnstake = (listingId: string) => {
    const listing = listings.find((entry) => entry.id === listingId);
    if (!listing) {
      return;
    }

    updateListing(listingId, (currentListing) => ({
      ...currentListing,
      isStaked: false,
      validator: undefined,
    }));

    addToast(`Stake released from ${listing.title}.`, 'info');
  };

  const handleDispute = (listingId: string, outcome: DisputeOutcome) => {
    const listing = listings.find((entry) => entry.id === listingId);
    if (!listing) {
      return;
    }

    updateListing(listingId, (currentListing) => ({
      ...currentListing,
      isStaked: false,
      validator: undefined,
    }));

    if (outcome === 'buyer_wins') {
      setResults((currentResults) => ({
        ...currentResults,
        lostDisputes: currentResults.lostDisputes + 1,
      }));

      addToast(
        `Buyer won the dispute on ${listing.title}. Your $${listing.stakeRequired} stake was slashed.`,
        'error',
      );
      return;
    }

    const commission = getListingCommission(listing.price);
    setResults((currentResults) => ({
      ...currentResults,
      completedValidations: currentResults.completedValidations + 1,
      realizedCommissions: currentResults.realizedCommissions + commission,
    }));

    addToast(
      `Validator won the dispute on ${listing.title}. You kept the stake and earned $${commission.toFixed(2)}.`,
      'success',
    );
  };

  return (
    <div className="relative min-h-screen overflow-hidden bg-[#050505] text-white">
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top_left,rgba(251,191,36,0.14),transparent_30%),radial-gradient(circle_at_80%_10%,rgba(34,197,94,0.16),transparent_24%),linear-gradient(180deg,#060606_0%,#0b0b0b_45%,#090909_100%)]" />

      <header className="relative z-10 border-b border-white/10">
        <div className="mx-auto flex max-w-7xl items-center justify-between px-4 py-5 sm:px-6 lg:px-8">
          <div className="flex items-center gap-4">
            <div className="flex h-11 w-11 items-center justify-center rounded-full border border-white/15 bg-white/5 text-lg font-semibold tracking-[0.3em]">
              B
            </div>
            <div>
              <p className="text-[0.65rem] uppercase tracking-[0.35em] text-white/45">
                Validator Demo
              </p>
              <h1 className="text-base font-semibold sm:text-lg">Bora Agent Market</h1>
            </div>
          </div>

          <button
            onClick={connectWallet}
            disabled={Boolean(userAddress) || isConnecting}
            className={`rounded-full px-5 py-2.5 text-sm font-semibold transition duration-200 ${
              userAddress
                ? 'border border-bora-green/50 bg-bora-green/20 text-bora-green'
                : 'border border-bora-gold/50 bg-bora-gold/20 text-bora-gold hover:bg-bora-gold/30'
            }`}
          >
            {isConnecting ? 'Connecting...' : userAddress ? 'Demo Ready' : 'Start Demo'}
          </button>
        </div>
      </header>

      <main className="relative z-10 mx-auto max-w-7xl space-y-8 px-4 py-8 sm:px-6 lg:px-8">
        <section className="grid gap-6 lg:grid-cols-[1.1fr_0.9fr]">
          <div className="panel">
            <p className="section-label">What This Demo Does</p>
            <h2 className="mt-3 max-w-2xl text-4xl font-semibold tracking-[-0.04em] sm:text-5xl">
              Test whether validator rewards are worth the risk.
            </h2>
            <p className="mt-4 max-w-2xl text-base leading-7 text-white/68">
              Pick listings, lock simulated USDC, and run disputes to see how a validator performs.
              The goal is simple: can Bora pay enough to justify staking capital on truth?
            </p>

            <div className="mt-6 flex flex-wrap gap-3">
              <button
                onClick={connectWallet}
                disabled={Boolean(userAddress) || isConnecting}
                className="rounded-full bg-white px-6 py-3 text-sm font-semibold text-black transition hover:bg-white/90 disabled:cursor-default disabled:bg-white/80"
              >
                {isConnecting ? 'Connecting...' : userAddress ? 'Wallet Connected' : 'Connect Mock Wallet'}
              </button>
              <a
                href="#listings"
                className="rounded-full border border-white/15 bg-white/5 px-6 py-3 text-sm font-semibold text-white/90 transition hover:bg-white/10"
              >
                Go To Listings
              </a>
            </div>

            <div className="mt-8 grid gap-4 sm:grid-cols-3">
              <div className="rounded-2xl border border-white/10 bg-white/4 p-4">
                <p className="section-label">Step 1</p>
                <p className="mt-2 text-lg font-medium">Connect</p>
                <p className="mt-2 text-sm text-white/58">Start the demo with a mock wallet.</p>
              </div>
              <div className="rounded-2xl border border-white/10 bg-white/4 p-4">
                <p className="section-label">Step 2</p>
                <p className="mt-2 text-lg font-medium">Stake</p>
                <p className="mt-2 text-sm text-white/58">Take a validation job from the listings below.</p>
              </div>
              <div className="rounded-2xl border border-white/10 bg-white/4 p-4">
                <p className="section-label">Step 3</p>
                <p className="mt-2 text-lg font-medium">Test a dispute</p>
                <p className="mt-2 text-sm text-white/58">See how a win or loss changes your outcome.</p>
              </div>
            </div>
          </div>

          <div className="poster-frame relative min-h-[20rem] overflow-hidden">
            <img
              src={heroImage}
              alt="Creative gear laid out for validator review"
              className="absolute inset-0 h-full w-full object-cover opacity-90"
            />
            <div className="absolute inset-0 bg-[linear-gradient(180deg,rgba(0,0,0,0.10)_0%,rgba(0,0,0,0.40)_38%,rgba(0,0,0,0.86)_100%)]" />
            <div className="absolute inset-x-0 bottom-0 p-6">
              <div className="rounded-[1.6rem] border border-white/10 bg-black/45 p-5 backdrop-blur-md">
                <p className="section-label">Quick Snapshot</p>
                <div className="mt-4 grid gap-4 sm:grid-cols-3">
                  <div>
                    <p className="text-xs uppercase tracking-[0.25em] text-white/45">Projected APY</p>
                    <p className="mt-2 text-3xl font-semibold text-bora-gold">
                      {protocolYieldSignal.toFixed(1)}%
                    </p>
                  </div>
                  <div>
                    <p className="text-xs uppercase tracking-[0.25em] text-white/45">Open Stakes</p>
                    <p className="mt-2 text-3xl font-semibold">{validatorStats.activeStakes}</p>
                  </div>
                  <div>
                    <p className="text-xs uppercase tracking-[0.25em] text-white/45">Listings Available</p>
                    <p className="mt-2 text-3xl font-semibold">{availableListings.length}</p>
                  </div>
                </div>
                <p className="mt-4 text-sm leading-6 text-white/62">
                  Use this as a decision board, not a landing page. Everything below should help
                  you act, measure, or compare.
                </p>
              </div>
            </div>
          </div>
        </section>

        <ValidatorDashboard userAddress={userAddress} stats={validatorStats} />

        <section className="grid gap-6 lg:grid-cols-[1.1fr_0.9fr]">
          <div className="panel">
            <p className="section-label">How To Read The Numbers</p>
            <div className="mt-4 grid gap-4 text-sm text-white/62 sm:grid-cols-2">
              <div>
                <p className="font-medium text-white">Active stake</p>
                <p className="mt-2">How much capital is currently locked across your positions.</p>
              </div>
              <div>
                <p className="font-medium text-white">Projected APY</p>
                <p className="mt-2">Estimated annual return based on your current open positions.</p>
              </div>
              <div>
                <p className="font-medium text-white">Realized earnings</p>
                <p className="mt-2">Commission actually earned after a validation survives dispute.</p>
              </div>
              <div>
                <p className="font-medium text-white">Success rate</p>
                <p className="mt-2">Completed validations divided by all completed decisions.</p>
              </div>
            </div>
          </div>

          {userAddress ? (
            <DisputeSimulator stakedListings={activeListings} onDispute={handleDispute} />
          ) : (
            <div className="panel flex min-h-[18rem] flex-col justify-between">
              <div>
                <p className="section-label">Dispute Test</p>
                <h3 className="mt-3 text-2xl font-semibold">Connect the mock wallet to unlock this panel.</h3>
                <p className="mt-3 max-w-md text-sm leading-7 text-white/68">
                  After you take at least one validation job, you can test two outcomes:
                  buyer wins or validator wins.
                </p>
              </div>
              <div className="grid gap-3 border-t border-white/10 pt-5 text-sm text-white/58">
                <div className="flex items-center justify-between">
                  <span>Dispute flow</span>
                  <span>AI to jury to council</span>
                </div>
                <div className="flex items-center justify-between">
                  <span>Stake lock</span>
                  <span>72 hours</span>
                </div>
              </div>
            </div>
          )}
        </section>

        <section id="listings" className="space-y-6">
          <div className="flex flex-col gap-3 border-b border-white/10 pb-5 lg:flex-row lg:items-end lg:justify-between">
            <div className="max-w-2xl">
              <p className="section-label">Listings</p>
              <h3 className="mt-2 text-3xl font-semibold tracking-[-0.03em]">
                Choose a listing and take a validation job.
              </h3>
              <p className="mt-3 text-sm leading-6 text-white/60">
                Listings already marked as staked are unavailable unless they were taken by you.
              </p>
            </div>
            <p className="text-sm text-white/55">
              {activeListings.length} active stake positions | {availableListings.length} open listings
            </p>
          </div>

          <div className="grid grid-cols-1 gap-6 md:grid-cols-2 xl:grid-cols-3">
            {listings.map((listing) => (
              <ListingCard
                key={listing.id}
                listing={listing}
                onStake={handleStake}
                onUnstake={handleUnstake}
                isUserValidator={Boolean(userAddress)}
              />
            ))}
          </div>
        </section>

        <footer className="border-t border-white/10 py-8">
          <div className="flex flex-col gap-2 text-sm text-white/52 sm:flex-row sm:items-center sm:justify-between">
            <p>
              Built by <span className="text-white/78">@iammcqwory</span>
            </p>
            <p>Trust-as-a-Protocol | Phase 0 validator economics sandbox</p>
          </div>
        </footer>
      </main>

      <ToastContainer toasts={toasts} onDismiss={dismissToast} />
    </div>
  );
}

export default App;
