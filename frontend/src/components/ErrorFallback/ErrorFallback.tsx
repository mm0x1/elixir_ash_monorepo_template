import type { FallbackProps } from "react-error-boundary";

const isDev = import.meta.env.DEV;

export function ErrorFallback({ error, resetErrorBoundary }: FallbackProps) {
  const errorObj = error instanceof Error ? error : new Error(String(error));

  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <div className="card bg-base-200 shadow-xl max-w-lg w-full">
        <div className="card-body text-center">
          <h2 className="card-title justify-center text-error">
            Something went wrong
          </h2>

          {isDev ? (
            <div className="text-left">
              <p className="font-mono text-sm text-error mb-2">
                {errorObj.name}: {errorObj.message}
              </p>
              {errorObj.stack && (
                <details className="collapse collapse-arrow bg-base-300">
                  <summary className="collapse-title text-sm font-medium">
                    Stack Trace
                  </summary>
                  <pre className="collapse-content text-xs overflow-auto">
                    {errorObj.stack}
                  </pre>
                </details>
              )}
            </div>
          ) : (
            <p className="text-base-content/70">
              An unexpected error occurred. Please try again.
            </p>
          )}

          <div className="card-actions justify-center mt-4">
            <button
              className="btn btn-primary"
              onClick={resetErrorBoundary}
            >
              Try Again
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
