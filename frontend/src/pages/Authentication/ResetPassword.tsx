import { useState, FormEvent } from "react";
import type { AuthResponse } from "@/types/auth";

export default function ResetPassword() {
  const [username, setUsername] = useState("");
  const [recoveryCode, setRecoveryCode] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [errors, setErrors] = useState<Record<string, string[]>>({});
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setErrors({});

    const response = await fetch("/api/auth/reset-password", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        username,
        recovery_code: recoveryCode,
        new_password: newPassword,
      }),
    });

    const data: AuthResponse = await response.json();

    if (data.success) {
      setSuccess(true);
    } else {
      setErrors(data.errors || {});
      setLoading(false);
    }
  }

  if (success) {
    return (
      <div>
        <h1>Password Reset Successful</h1>
        <p>Your password has been reset.</p>
        <a href="/auth/sign-in">Sign in with your new password</a>
      </div>
    );
  }

  return (
    <div>
      <h1>Reset Password</h1>
      <p>Enter your username and one of your recovery codes.</p>

      <form onSubmit={handleSubmit}>
        <div>
          <label htmlFor="username">Username</label>
          <input
            id="username"
            type="text"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            required
            autoComplete="username"
          />
        </div>

        <div>
          <label htmlFor="recovery_code">Recovery Code</label>
          <input
            id="recovery_code"
            type="text"
            value={recoveryCode}
            onChange={(e) => setRecoveryCode(e.target.value.toUpperCase())}
            placeholder="XXXXXXXXXX"
            required
          />
        </div>

        <div>
          <label htmlFor="new_password">New Password</label>
          <input
            id="new_password"
            type="password"
            value={newPassword}
            onChange={(e) => setNewPassword(e.target.value)}
            minLength={8}
            required
            autoComplete="new-password"
          />
        </div>

        {errors.base && <div>{errors.base.join(", ")}</div>}

        <button type="submit" disabled={loading}>
          {loading ? "Resetting..." : "Reset Password"}
        </button>
      </form>

      <p>
        <a href="/auth/sign-in">Back to Sign In</a>
      </p>
    </div>
  );
}
