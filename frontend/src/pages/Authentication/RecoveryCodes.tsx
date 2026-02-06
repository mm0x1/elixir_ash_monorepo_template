import { useState } from "react";
import { router } from "@inertiajs/react";
import type { RecoveryCodesPageProps, RecoveryCodesResponse } from "@/types/auth";

export default function RecoveryCodes({
  current_user,
  first_time,
}: RecoveryCodesPageProps) {
  const [codes, setCodes] = useState<string[] | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [confirmed, setConfirmed] = useState(false);

  async function generateCodes() {
    setLoading(true);
    setError(null);

    const response = await fetch("/api/auth/recovery-codes", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
    });

    const data: RecoveryCodesResponse = await response.json();

    if (data.success && data.data) {
      setCodes(data.data.recovery_codes);
    } else {
      setError(data.errors?.base?.join(", ") || "Failed to generate codes");
    }
    setLoading(false);
  }

  function handleConfirm() {
    setConfirmed(true);
    if (first_time) {
      router.visit("/");
    }
  }

  function handleCopy() {
    if (codes) {
      navigator.clipboard.writeText(codes.join("\n"));
    }
  }

  if (!current_user) {
    return (
      <div>
        <h1>Recovery Codes</h1>
        <p>You must be signed in to manage recovery codes.</p>
        <a href="/auth/sign-in">Sign In</a>
      </div>
    );
  }

  // Show codes after generation
  if (codes) {
    return (
      <div>
        <h1>Recovery Codes</h1>
        <p>
          <strong>
            Save these codes securely. They will not be shown again.
          </strong>
        </p>
        <p>Each code can only be used once to reset your password.</p>

        <div>
          <pre>
            {codes.map((code, i) => (
              <div key={i}>{code}</div>
            ))}
          </pre>
        </div>

        <div>
          <button type="button" onClick={handleCopy}>
            Copy to Clipboard
          </button>
        </div>

        <div>
          <label>
            <input
              type="checkbox"
              checked={confirmed}
              onChange={(e) => setConfirmed(e.target.checked)}
            />
            I have saved these codes
          </label>
        </div>

        <button type="button" onClick={handleConfirm} disabled={!confirmed}>
          {first_time ? "Continue to App" : "Done"}
        </button>
      </div>
    );
  }

  // Initial state - show generate/regenerate button
  const hasExistingCodes = current_user.has_recovery_codes;

  return (
    <div>
      <h1>Recovery Codes</h1>

      {current_user.is_anonymous ? (
        <div>
          <p>Anonymous users cannot generate recovery codes.</p>
          <p>
            <a href="/auth/convert">Convert to a registered account</a> to
            enable recovery codes.
          </p>
        </div>
      ) : (
        <>
          {hasExistingCodes ? (
            <div>
              <p>
                You have {current_user.recovery_codes_count} recovery codes
                remaining.
              </p>
              <p>Regenerating will invalidate all existing codes.</p>
            </div>
          ) : (
            <div>
              <p>You haven&apos;t generated recovery codes yet.</p>
              <p>Recovery codes let you reset your password if you forget it.</p>
            </div>
          )}

          {error && <div>{error}</div>}

          <button type="button" onClick={generateCodes} disabled={loading}>
            {loading
              ? "Generating..."
              : hasExistingCodes
                ? "Regenerate Codes"
                : "Generate Codes"}
          </button>
        </>
      )}

      {!first_time && (
        <p>
          <a href="/profile">Back to Profile</a>
        </p>
      )}
    </div>
  );
}
