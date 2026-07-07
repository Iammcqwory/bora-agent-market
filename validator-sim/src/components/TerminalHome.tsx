import { useEffect, useMemo, useState } from 'react';

interface TerminalHomeProps {
  onEnterSimulator: () => void;
  onAbout: () => void;
}

const TERMINAL_LINES = [
  '> bora agent market v0.1',
  '> trust-as-a-protocol',
  "> stake capital on truth. earn when you're right.",
];

const TYPE_INTERVAL_MS = 18;

export function TerminalHome({ onEnterSimulator, onAbout }: TerminalHomeProps) {
  const totalChars = useMemo(
    () => TERMINAL_LINES.reduce((count, line) => count + line.length, 0),
    [],
  );
  const [typedChars, setTypedChars] = useState(0);
  const isDone = typedChars >= totalChars;

  useEffect(() => {
    if (isDone) {
      return;
    }
    const interval = setInterval(() => {
      setTypedChars((count) => Math.min(count + 1, totalChars));
    }, TYPE_INTERVAL_MS);
    return () => clearInterval(interval);
  }, [isDone, totalChars]);

  const lines = TERMINAL_LINES.map((line, index) => {
    const offset = TERMINAL_LINES.slice(0, index).reduce((count, prev) => count + prev.length, 0);
    const visibleCount = Math.max(0, Math.min(line.length, typedChars - offset));
    return { full: line, visible: line.slice(0, visibleCount) };
  });
  const activeLineIndex = lines.findIndex((line) => line.visible.length < line.full.length);

  return (
    <div
      className="flex min-h-screen flex-col items-center justify-center bg-[#050505] px-6 font-mono text-bora-green"
      onClick={() => setTypedChars(totalChars)}
    >
      <div className="w-full max-w-xl">
        {lines.map((line, index) => {
          if (index > 0 && line.visible.length === 0 && index !== activeLineIndex) {
            return null;
          }
          return (
            <p key={line.full} className="text-sm leading-8 sm:text-base">
              {line.visible}
              {index === activeLineIndex && <span className="terminal-cursor">█</span>}
            </p>
          );
        })}
        {isDone && (
          <p className="text-sm leading-8 sm:text-base">
            {'> '}
            <span className="terminal-cursor">█</span>
          </p>
        )}

        <div
          className={`mt-10 flex flex-wrap gap-4 transition-opacity duration-500 ${
            isDone ? 'opacity-100' : 'pointer-events-none opacity-0'
          }`}
        >
          <button
            onClick={onEnterSimulator}
            className="rounded border border-bora-green/40 px-5 py-2.5 text-sm lowercase tracking-wide transition hover:bg-bora-green/10"
          >
            [ enter simulator ]
          </button>
          <button
            onClick={onAbout}
            className="rounded border border-bora-green/25 px-5 py-2.5 text-sm lowercase tracking-wide text-bora-green/70 transition hover:bg-bora-green/10 hover:text-bora-green"
          >
            [ about ]
          </button>
        </div>
      </div>
    </div>
  );
}
