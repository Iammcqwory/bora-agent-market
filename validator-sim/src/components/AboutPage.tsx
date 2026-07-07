import { useEffect, useState } from 'react';

interface AboutPageProps {
  onEnterSimulator: () => void;
}

type SectionId = 'overview' | 'flow' | 'numbers' | 'protocol';

const METRIC_GUIDE = [
  {
    label: 'Active stake',
    description: 'How much capital is currently locked across your positions.',
  },
  {
    label: 'Projected APY',
    description: 'Estimated annual return based on your current open positions.',
  },
  {
    label: 'Realized earnings',
    description: 'Commission actually earned after a validation survives dispute.',
  },
  {
    label: 'Success rate',
    description: 'Completed validations divided by all completed decisions.',
  },
];

const PROTOCOL_FACTS = [
  { label: 'Validation commission', value: '1.0% of item price' },
  { label: 'Stake requirement', value: '20-75% of item value' },
  { label: 'Stake lock', value: '72 hours' },
  { label: 'Dispute flow', value: 'AI to jury to council' },
  { label: 'Insurance coverage', value: 'First 40% of slashing losses' },
  { label: 'Validator target APY', value: '25-40%' },
];

const SECTIONS: { id: SectionId; label: string }[] = [
  { id: 'overview', label: 'Overview' },
  { id: 'flow', label: 'Flow' },
  { id: 'numbers', label: 'Numbers' },
  { id: 'protocol', label: 'Protocol' },
];

export function AboutPage({ onEnterSimulator }: AboutPageProps) {
  const [active, setActive] = useState<SectionId>('overview');
  const [expanded, setExpanded] = useState(false);
  const [isDesktop, setIsDesktop] = useState(false);
  const activeSection = SECTIONS.find((section) => section.id === active) ?? SECTIONS[0];

  useEffect(() => {
    const query = window.matchMedia('(min-width: 768px)');
    const update = () => setIsDesktop(query.matches);
    update();
    query.addEventListener('change', update);
    return () => query.removeEventListener('change', update);
  }, []);

  // On desktop the pill collapses to just the active item until hovered/focused.
  const collapsed = isDesktop && !expanded;

  return (
    <div className="relative min-h-[70vh]">
      <div
        aria-hidden="true"
        key={`word-${active}`}
        style={{ color: 'rgba(255,255,255,0.05)' }}
        className="about-word pointer-events-none absolute inset-x-0 top-8 select-none text-center text-[18vw] font-bold uppercase leading-none tracking-[-0.06em]"
      >
        {activeSection.label}
      </div>

      <nav
        aria-label="About sections"
        onMouseEnter={() => setExpanded(true)}
        onMouseLeave={() => setExpanded(false)}
        onFocusCapture={() => setExpanded(true)}
        onBlurCapture={() => setExpanded(false)}
        className="sticky top-6 z-20 mx-auto flex w-fit items-center rounded-full border border-white/12 bg-black/70 p-1.5 shadow-[0_16px_48px_rgba(0,0,0,0.55)] backdrop-blur-xl"
      >
        {SECTIONS.map((section) => {
          const isActive = section.id === active;
          const isCollapsed = collapsed && !isActive;
          return (
            <button
              key={section.id}
              onClick={() => setActive(section.id)}
              aria-hidden={isCollapsed}
              tabIndex={isCollapsed ? -1 : 0}
              style={{
                maxWidth: isCollapsed ? 0 : '10rem',
                opacity: isCollapsed ? 0 : 1,
                paddingLeft: isCollapsed ? 0 : '1rem',
                paddingRight: isCollapsed ? 0 : '1rem',
                transform: isCollapsed ? 'scale(0.85)' : 'scale(1)',
              }}
              className={`flex items-center gap-2 overflow-hidden whitespace-nowrap rounded-full py-2 text-sm font-medium transition-all duration-300 ease-out ${
                isActive ? 'bg-white/10 text-white' : 'text-white/50 hover:text-white'
              }`}
            >
              <span
                className={`h-1.5 w-1.5 shrink-0 rounded-full transition-colors duration-300 ${
                  isActive ? 'bg-bora-green' : 'bg-white/25'
                }`}
              />
              {section.label}
            </button>
          );
        })}
      </nav>

      <div key={`panel-${active}`} className="about-panel relative z-10 mx-auto mt-16 max-w-3xl">
        {active === 'overview' && (
          <section className="panel">
            <p className="section-label">Overview</p>
            <h2 className="mt-3 text-4xl font-semibold tracking-[-0.04em] sm:text-5xl">
              Test whether validator rewards are worth the risk.
            </h2>
            <p className="mt-4 text-base leading-7 text-white/68">
              Bora validators lock USDC behind marketplace listings and earn commission when their
              judgement survives disputes. This sandbox lets you test whether the rewards justify
              the risk — with simulated money.
            </p>
            <p className="mt-4 text-base leading-7 text-white/68">
              Pick listings, lock simulated USDC, and run disputes to see how a validator performs.
              The goal is simple: can Bora pay enough to justify staking capital on truth?
            </p>
          </section>
        )}

        {active === 'flow' && (
          <section className="panel">
            <p className="section-label">How The Demo Flows</p>
            <ol className="mt-4 space-y-5 text-sm leading-6 text-white/68">
              <li>
                <span className="font-medium text-white">1. Connect</span> — start the demo with a
                mock wallet. No real funds are involved anywhere.
              </li>
              <li>
                <span className="font-medium text-white">2. Stake</span> — take a validation job
                from the listings. Your simulated USDC locks behind that listing.
              </li>
              <li>
                <span className="font-medium text-white">3. Test a dispute</span> — resolve a
                staked listing as buyer-win or validator-win and watch how earnings, exposure, and
                success rate respond.
              </li>
            </ol>
          </section>
        )}

        {active === 'numbers' && (
          <section className="panel">
            <p className="section-label">How To Read The Numbers</p>
            <div className="mt-4 grid gap-5 text-sm text-white/62 sm:grid-cols-2">
              {METRIC_GUIDE.map((metric) => (
                <div key={metric.label}>
                  <p className="font-medium text-white">{metric.label}</p>
                  <p className="mt-2">{metric.description}</p>
                </div>
              ))}
            </div>
          </section>
        )}

        {active === 'protocol' && (
          <section className="panel">
            <p className="section-label">Protocol Facts</p>
            <div className="mt-4 grid gap-x-8 gap-y-4 sm:grid-cols-2">
              {PROTOCOL_FACTS.map((fact) => (
                <div
                  key={fact.label}
                  className="flex items-center justify-between gap-4 border-b border-white/10 pb-3 text-sm"
                >
                  <span className="text-white/55">{fact.label}</span>
                  <span className="text-right font-medium text-white/85">{fact.value}</span>
                </div>
              ))}
            </div>
            <p className="mt-6 text-sm leading-6 text-white/55">
              This is a Phase 0 economics sandbox: everything runs on mock data in your browser.
              The on-chain protocol (staking, marketplace, disputes, insurance pool) lives in the
              contracts workspace of this repo.
            </p>
          </section>
        )}

        <div className="mt-8 flex justify-center">
          <button
            onClick={onEnterSimulator}
            className="rounded-full bg-white px-6 py-3 text-sm font-semibold text-black transition hover:bg-white/90"
          >
            Enter The Simulator
          </button>
        </div>
      </div>
    </div>
  );
}
