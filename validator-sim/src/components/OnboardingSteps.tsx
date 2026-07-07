export interface OnboardingStep {
  label: string;
  description: string;
  done: boolean;
}

interface OnboardingStepsProps {
  steps: OnboardingStep[];
  currentStepIndex: number;
}

export function OnboardingSteps({ steps, currentStepIndex }: OnboardingStepsProps) {
  return (
    <ol className="flex flex-col gap-3 sm:flex-row">
      {steps.map((step, index) => {
        const isDone = step.done;
        const isCurrent = index === currentStepIndex;
        return (
          <li
            key={step.label}
            className={`flex flex-1 items-start gap-3 rounded-2xl border p-4 text-left transition duration-200 ${
              isDone
                ? 'border-bora-green/40 bg-bora-green/10'
                : isCurrent
                  ? 'border-bora-gold/50 bg-bora-gold/10'
                  : 'border-white/10 bg-white/[0.04]'
            }`}
          >
            <span
              className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-full border text-xs font-semibold ${
                isDone
                  ? 'border-bora-green/60 bg-bora-green/20 text-bora-green'
                  : isCurrent
                    ? 'border-bora-gold/60 bg-bora-gold/20 text-bora-gold'
                    : 'border-white/15 text-white/45'
              }`}
            >
              {isDone ? '✓' : index + 1}
            </span>
            <span>
              <span
                className={`block text-sm font-semibold ${
                  isDone ? 'text-bora-green' : isCurrent ? 'text-bora-gold' : 'text-white/85'
                }`}
              >
                {step.label}
                {isCurrent && !isDone && (
                  <span className="ml-2 text-[0.6rem] font-semibold uppercase tracking-[0.18em] text-bora-gold/80">
                    Do this next
                  </span>
                )}
              </span>
              <span className="mt-1 block text-xs leading-5 text-white/55">
                {step.description}
              </span>
            </span>
          </li>
        );
      })}
    </ol>
  );
}
