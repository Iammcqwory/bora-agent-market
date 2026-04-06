import { useEffect } from 'react';

export interface Toast {
  id: string;
  message: string;
  type: 'success' | 'error' | 'info';
}

interface ToastNotificationProps {
  toast: Toast;
  onDismiss: (id: string) => void;
}

const toastStyles = {
  success: {
    container: 'border-bora-green/50 bg-bora-green/20',
    text: 'text-bora-green',
    icon: 'OK',
  },
  error: {
    container: 'border-red-500/50 bg-red-500/20',
    text: 'text-red-400',
    icon: 'ERR',
  },
  info: {
    container: 'border-bora-gold/50 bg-bora-gold/20',
    text: 'text-bora-gold',
    icon: 'INFO',
  },
} as const;

export function ToastNotification({ toast, onDismiss }: ToastNotificationProps) {
  useEffect(() => {
    const timer = window.setTimeout(() => {
      onDismiss(toast.id);
    }, 4000);

    return () => window.clearTimeout(timer);
  }, [toast.id, onDismiss]);

  const styles = toastStyles[toast.type];

  return (
    <div className={`${styles.container} toast-enter rounded-lg border p-4 shadow-lg backdrop-blur-md`}>
      <div className="flex items-start gap-3">
        <div className={`${styles.text} text-xs font-bold tracking-wide`}>{styles.icon}</div>
        <p className={`${styles.text} flex-1 text-sm`}>{toast.message}</p>
        <button
          type="button"
          onClick={() => onDismiss(toast.id)}
          className="text-white/50 hover:text-white/80"
          aria-label="Dismiss notification"
        >
          x
        </button>
      </div>
    </div>
  );
}

interface ToastContainerProps {
  toasts: Toast[];
  onDismiss: (id: string) => void;
}

export function ToastContainer({ toasts, onDismiss }: ToastContainerProps) {
  return (
    <div className="fixed bottom-4 right-4 z-50 w-96 max-w-full space-y-3">
      {toasts.map((toast) => (
        <ToastNotification key={toast.id} toast={toast} onDismiss={onDismiss} />
      ))}
    </div>
  );
}
