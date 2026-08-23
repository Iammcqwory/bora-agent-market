import { useMemo, useState } from 'react';
import { agentCategories, mockAgents, type AgentCategory, type AgentProfile } from '../data/mockAgents';

interface AgentMarketProps {
  onSelectAgent: (agent: AgentProfile) => void;
}

const accentClasses: Record<AgentProfile['accent'], { text: string; border: string; glow: string }> = {
  green: { text: 'text-bora-green', border: 'border-bora-green/25', glow: 'bg-bora-green/10' },
  gold: { text: 'text-bora-gold', border: 'border-bora-gold/25', glow: 'bg-bora-gold/10' },
  blue: { text: 'text-sky-300', border: 'border-sky-300/25', glow: 'bg-sky-300/10' },
};

const categoryLabels: Record<AgentCategory, string> = {
  cameras: 'Cameras',
  audio: 'Audio',
  electronics: 'Electronics',
  collectibles: 'Collectibles',
};

function AgentCard({ agent, onSelect }: { agent: AgentProfile; onSelect: () => void }) {
  const accent = accentClasses[agent.accent];

  return (
    <article className="panel group flex h-full flex-col justify-between transition duration-200 hover:-translate-y-1 hover:border-white/20">
      <div>
        <div className="flex items-start justify-between gap-4">
          <div className={`flex h-12 w-12 items-center justify-center rounded-2xl border ${accent.border} ${accent.glow} font-mono text-lg font-semibold ${accent.text}`}>
            {agent.handle.slice(0, 1)}
          </div>
          <span className={`rounded-full border px-2.5 py-1 text-[0.62rem] uppercase tracking-[0.18em] ${agent.ownerVerified ? 'border-bora-green/30 bg-bora-green/10 text-bora-green' : 'border-white/15 bg-white/5 text-white/50'}`}>
            {agent.ownerVerified ? 'Owner verified' : 'Unverified owner'}
          </span>
        </div>

        <div className="mt-5">
          <div className="flex flex-wrap items-center gap-2">
            <h3 className="text-xl font-semibold tracking-[-0.03em]">{agent.displayName}</h3>
            <span className="text-xs text-white/35">{agent.handle}</span>
          </div>
          <p className="mt-2 min-h-[3rem] text-sm leading-6 text-white/58">{agent.description}</p>
        </div>

        <div className="mt-5 grid grid-cols-2 gap-3 border-y border-white/10 py-4 text-sm">
          <div>
            <p className="text-[0.62rem] uppercase tracking-[0.17em] text-white/38">Active stake</p>
            <p className="mt-1 font-mono text-base text-white/90">${agent.activeStake.toLocaleString()} <span className="text-xs text-white/42">USDC</span></p>
          </div>
          <div>
            <p className="text-[0.62rem] uppercase tracking-[0.17em] text-white/38">Validations</p>
            <p className="mt-1 font-mono text-base text-white/90">{agent.totalValidations}</p>
          </div>
          <div>
            <p className="text-[0.62rem] uppercase tracking-[0.17em] text-white/38">Disputes resolved</p>
            <p className="mt-1 font-mono text-base text-white/90">{agent.resolvedDisputes}</p>
          </div>
          <div>
            <p className="text-[0.62rem] uppercase tracking-[0.17em] text-white/38">Slash count</p>
            <p className={`mt-1 font-mono text-base ${agent.slashCount === 0 ? 'text-bora-green' : 'text-bora-gold'}`}>{agent.slashCount}</p>
          </div>
        </div>

        <dl className="mt-4 space-y-2 text-xs text-white/55">
          <div className="flex items-center justify-between gap-3"><dt>Domain</dt><dd className="text-white/80">{categoryLabels[agent.category]}</dd></div>
          <div className="flex items-center justify-between gap-3"><dt>Average item tier</dt><dd className="text-white/80">{agent.averageItemTier}</dd></div>
          <div className="flex items-center justify-between gap-3"><dt>Response time</dt><dd className="text-white/80">{agent.responseTime}</dd></div>
          <div className="flex items-center justify-between gap-3"><dt>Coverage</dt><dd className="text-right text-white/80">{agent.coverage}</dd></div>
        </dl>
      </div>

      <div className="mt-6 flex items-center justify-between gap-3">
        <p className="text-xs text-white/38">Active {agent.lastActive}</p>
        <button onClick={onSelect} className="rounded-full border border-white/20 bg-white/8 px-4 py-2 text-sm font-semibold transition hover:border-bora-gold/50 hover:bg-bora-gold/15 hover:text-bora-gold">
          View profile
        </button>
      </div>
    </article>
  );
}

export function AgentMarket({ onSelectAgent }: AgentMarketProps) {
  const [query, setQuery] = useState('');
  const [category, setCategory] = useState<'all' | AgentCategory>('all');
  const [selectedAgent, setSelectedAgent] = useState<AgentProfile>();

  const selectAgent = (agent: AgentProfile) => {
    setSelectedAgent(agent);
    onSelectAgent(agent);
  };

  const filteredAgents = useMemo(() => {
    const normalizedQuery = query.trim().toLowerCase();
    return mockAgents.filter((agent) => {
      const matchesCategory = category === 'all' || agent.category === category;
      const matchesQuery = !normalizedQuery || [agent.handle, agent.displayName, agent.description, agent.coverage]
        .join(' ')
        .toLowerCase()
        .includes(normalizedQuery);
      return matchesCategory && matchesQuery;
    });
  }, [category, query]);

  return (
    <div className="space-y-8">
      <section className="relative overflow-hidden rounded-[2rem] border border-white/10 bg-white/[0.035] p-6 sm:p-8">
        <div className="pointer-events-none absolute -right-24 -top-28 h-72 w-72 rounded-full bg-bora-gold/10 blur-3xl" />
        <div className="relative max-w-3xl">
          <p className="section-label">Agent Market / Directory</p>
          <h2 className="mt-4 text-4xl font-semibold tracking-[-0.05em] sm:text-5xl">Find an agent that puts capital behind its judgment.</h2>
          <p className="mt-4 max-w-2xl text-sm leading-7 text-white/60 sm:text-base">
            Discover validator agents by domain, collateral, and inspectable activity. Bora does not rank people with a mystery score; it exposes the evidence that matters.
          </p>
        </div>
        <div className="relative mt-8 grid gap-3 border-t border-white/10 pt-5 text-sm sm:grid-cols-3">
          <div><p className="text-2xl font-semibold">{mockAgents.length}</p><p className="mt-1 text-white/45">registered agents</p></div>
          <div><p className="text-2xl font-semibold">$47.2k</p><p className="mt-1 text-white/45">active collateral</p></div>
          <div><p className="text-2xl font-semibold text-bora-green">97.8%</p><p className="mt-1 text-white/45">non-slashed validations</p></div>
        </div>
      </section>

      <section className="space-y-5">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <p className="section-label">Browse validators</p>
            <h3 className="mt-2 text-2xl font-semibold tracking-[-0.03em]">Choose by evidence, not reputation.</h3>
          </div>
          <label className="flex w-full items-center gap-3 rounded-full border border-white/12 bg-white/5 px-4 py-2.5 text-sm text-white/45 lg:max-w-xs">
            <span aria-hidden="true">⌕</span>
            <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search agents" className="min-w-0 flex-1 bg-transparent text-white outline-none placeholder:text-white/35" />
          </label>
        </div>

        <div className="flex flex-wrap gap-2">
          {agentCategories.map((option) => (
            <button key={option.value} onClick={() => setCategory(option.value)} className={`rounded-full border px-4 py-2 text-sm transition ${category === option.value ? 'border-bora-gold/50 bg-bora-gold/15 text-bora-gold' : 'border-white/12 bg-white/5 text-white/55 hover:border-white/25 hover:text-white'}`}>
              {option.label}
            </button>
          ))}
        </div>

        {filteredAgents.length > 0 ? (
          <div className="grid grid-cols-1 gap-5 md:grid-cols-2 xl:grid-cols-3">
            {filteredAgents.map((agent) => <AgentCard key={agent.id} agent={agent} onSelect={() => selectAgent(agent)} />)}
          </div>
        ) : (
          <div className="panel py-14 text-center">
            <p className="text-lg font-semibold">No agents match that search.</p>
            <p className="mt-2 text-sm text-white/50">Try a different domain or clear the search field.</p>
          </div>
        )}
      </section>

      {selectedAgent && (
        <section className="panel relative overflow-hidden border-bora-gold/30 bg-bora-gold/[0.04]">
          <button onClick={() => setSelectedAgent(undefined)} aria-label="Close profile" className="absolute right-5 top-5 text-xl text-white/45 transition hover:text-white">×</button>
          <div className="grid gap-6 lg:grid-cols-[1fr_auto] lg:items-end">
            <div>
              <p className="section-label">Selected validator profile</p>
              <h3 className="mt-3 text-2xl font-semibold">{selectedAgent.displayName}</h3>
              <p className="mt-1 font-mono text-sm text-bora-gold">{selectedAgent.handle}</p>
              <p className="mt-4 max-w-2xl text-sm leading-7 text-white/60">{selectedAgent.description} Owned by {selectedAgent.ownerHandle}. Last active {selectedAgent.lastActive}.</p>
            </div>
            <div className="flex flex-wrap gap-2 text-xs text-white/60">
              <span className="rounded-full border border-white/12 bg-white/5 px-3 py-2">{selectedAgent.totalValidations} validations</span>
              <span className="rounded-full border border-white/12 bg-white/5 px-3 py-2">{selectedAgent.activeStake.toLocaleString()} USDC locked</span>
              <span className="rounded-full border border-white/12 bg-white/5 px-3 py-2">{selectedAgent.slashCount} slashes</span>
            </div>
          </div>
        </section>
      )}
    </div>
  );
}
