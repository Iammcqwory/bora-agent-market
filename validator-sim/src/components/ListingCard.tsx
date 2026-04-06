import {
  CONNECTED_VALIDATOR_LABEL,
  getListingCommission,
  isListingManagedByCurrentValidator,
} from '../lib/validatorSimulation';
import type { Listing } from '../data/mockListings';

interface ListingCardProps {
  listing: Listing;
  onStake: (listingId: string) => void;
  onUnstake: (listingId: string) => void;
  isUserValidator: boolean;
}

const categoryLabels: Record<Listing['category'], string> = {
  camera: 'Camera',
  lens: 'Lens',
  audio: 'Audio',
  lighting: 'Lighting',
  computer: 'Computer',
};

export function ListingCard({
  listing,
  onStake,
  onUnstake,
  isUserValidator,
}: ListingCardProps) {
  const listingCommission = getListingCommission(listing.price);
  const isManagedByCurrentValidator = isListingManagedByCurrentValidator(
    listing,
    CONNECTED_VALIDATOR_LABEL,
  );
  const isLockedByAnotherValidator = listing.isStaked && !isManagedByCurrentValidator;

  return (
    <article
      className={`panel p-0 transition duration-200 hover:-translate-y-1 hover:bg-white/[0.045] ${
        listing.isStaked ? 'glow-green' : ''
      }`}
    >
      <div className="relative overflow-hidden rounded-t-[1.75rem]">
        <img
          src={listing.imageUrl}
          alt={listing.title}
          className="h-48 w-full object-cover"
          loading="lazy"
        />
        <div className="absolute inset-0 bg-[linear-gradient(180deg,rgba(0,0,0,0.02),rgba(0,0,0,0.50))]" />
        <div className="absolute left-4 top-4 flex flex-wrap gap-2">
          <span className="rounded-full border border-white/15 bg-black/45 px-3 py-1 text-xs font-medium text-white/85 backdrop-blur">
            {categoryLabels[listing.category]}
          </span>
          <span className="rounded-full border border-white/15 bg-black/45 px-3 py-1 text-xs font-medium text-white/85 backdrop-blur">
            {listing.condition}
          </span>
        </div>
        {listing.isStaked ? (
          <div className="absolute bottom-4 left-4 rounded-full border border-bora-green/50 bg-bora-green/20 px-3 py-1 text-xs font-semibold text-bora-green backdrop-blur">
            {isManagedByCurrentValidator ? 'Your active stake' : `Taken by ${listing.validator}`}
          </div>
        ) : null}
      </div>

      <div className="space-y-4 p-5">
        <div>
          <h3 className="text-xl font-semibold leading-tight">{listing.title}</h3>
          <p className="mt-2 text-sm leading-6 text-white/62">{listing.description}</p>
        </div>

        <div className="grid gap-3 rounded-2xl border border-white/10 bg-white/[0.03] p-4 text-sm sm:grid-cols-2">
          <div>
            <p className="text-xs uppercase tracking-[0.22em] text-white/38">Item price</p>
            <p className="mt-2 text-2xl font-semibold text-bora-gold">${listing.price}</p>
          </div>
          <div>
            <p className="text-xs uppercase tracking-[0.22em] text-white/38">Stake required</p>
            <p className="mt-2 text-2xl font-semibold">${listing.stakeRequired}</p>
          </div>
          <div>
            <p className="text-xs uppercase tracking-[0.22em] text-white/38">Projected commission</p>
            <p className="mt-2 text-lg font-semibold text-bora-green">
              ${listingCommission.toFixed(2)}
            </p>
          </div>
          <div>
            <p className="text-xs uppercase tracking-[0.22em] text-white/38">Seller</p>
            <p className="mt-2 text-sm text-white/72">
              {listing.seller.slice(0, 6)}...{listing.seller.slice(-4)}
            </p>
          </div>
        </div>

        {isUserValidator ? (
          <button
            onClick={() => (listing.isStaked ? onUnstake(listing.id) : onStake(listing.id))}
            disabled={isLockedByAnotherValidator}
            className={`w-full rounded-full px-4 py-3 text-sm font-semibold transition-all ${
              listing.isStaked
                ? 'border border-red-500/50 bg-red-500/20 text-red-400 hover:bg-red-500/30'
                : 'border border-bora-green/50 bg-bora-green/20 text-bora-green hover:bg-bora-green/30'
            } disabled:cursor-not-allowed disabled:opacity-50`}
          >
            {listing.isStaked
              ? isManagedByCurrentValidator
                ? 'Release my stake'
                : 'Already taken'
              : `Take validation job for $${listing.stakeRequired}`}
          </button>
        ) : (
          <div className="rounded-full border border-white/10 bg-white/[0.03] px-4 py-3 text-center text-sm text-white/55">
            Connect the mock wallet to take this validation job.
          </div>
        )}
      </div>
    </article>
  );
}
