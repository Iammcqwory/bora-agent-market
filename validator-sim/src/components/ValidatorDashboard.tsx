import type { ValidatorStats } from '../lib/validatorSimulation';

interface ValidatorDashboardProps {
  userAddress?: string;
  stats: ValidatorStats;
}

interface MetricProps {
  label: string;
  value: string;
  tone?: 'default' | 'gold' | 'green';
  detail: string;
}

function Metric({ label, value, tone = 'default', detail }: MetricProps) {
  const toneClass =
    tone === 'gold' ? 'text-bora-gold' : tone === 'green' ? 'text-bora-green' : 'text-white';

  return (
    <div className="border-t border-white/10 pt-4 first:border-t-0 first:pt-0 lg:border-t-0 lg:border-l lg:border-white/10 lg:pl-6 lg:first:border-l-0 lg:first:pl-0">
      <p className="text-[0.68rem] uppercase tracking-[0.28em] text-white/40">{label}</p>
      <p className={`mt-2 text-3xl font-semibold ${toneClass}`}>{value}</p>
      <p className="mt-2 text-sm text-white/55">{detail}</p>
    </div>
  );
}

export function ValidatorDashboard({ userAddress, stats }: ValidatorDashboardProps) {
  if (!userAddress) {
    return (
      <div className="panel min-h-[18rem]">
        <p className="section-label">Validator Workspace</p>
        <h3 className="mt-3 max-w-lg text-3xl font-semibold tracking-[-0.03em]">
          Connect a wallet to turn the board into a live underwriting view.
        </h3>
        <p className="mt-4 max-w-xl text-sm leading-7 text-white/68">
          Once connected, the dashboard will track active exposure, projected APY, completed
          validations, and dispute pressure across your simulated positions.
        </p>
      </div>
    );
  }

  const totalDecisions = stats.completedValidations + stats.lostDisputes;
  const successRate =
    totalDecisions > 0 ? `${((stats.completedValidations / totalDecisions) * 100).toFixed(0)}%` : 'N/A';

  return (
    <div className="panel min-h-[18rem]">
      <div className="flex flex-col gap-4 border-b border-white/10 pb-6 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <p className="section-label">Validator Workspace</p>
          <h3 className="mt-2 text-3xl font-semibold tracking-[-0.03em]">Live economics readout</h3>
        </div>
        <div className="rounded-full border border-white/10 bg-white/5 px-4 py-2 text-sm text-white/70">
          {userAddress.slice(0, 6)}...{userAddress.slice(-4)}
        </div>
      </div>

      <div className="grid gap-6 py-6 lg:grid-cols-4">
        <Metric
          label="Active Stake"
          value={`$${stats.totalStaked.toFixed(0)}`}
          detail={`${stats.activeStakes} live listing positions`}
        />
        <Metric
          label="Projected APY"
          value={`${stats.currentAPY.toFixed(1)}%`}
          tone="gold"
          detail={`$${stats.projectedCommissions.toFixed(2)} projected from active positions`}
        />
        <Metric
          label="Realized Earnings"
          value={`$${stats.realizedCommissions.toFixed(2)}`}
          tone="green"
          detail={`${stats.completedValidations} validations converted to payout`}
        />
        <Metric
          label="Success Rate"
          value={successRate}
          detail={`${stats.lostDisputes} disputes lost so far`}
        />
      </div>

      <div className="grid gap-4 border-t border-white/10 pt-5 text-sm text-white/60 sm:grid-cols-2">
        <p>Active capital is calculated from currently staked listings, not cumulative history.</p>
        <p>Projected APY assumes roughly 22 similar validations per year at current position size.</p>
      </div>
    </div>
  );
}
