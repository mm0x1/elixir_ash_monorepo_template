import { useState, FormEvent } from "react";
import { router } from "@inertiajs/react";
import type { AuthResponse } from "@/types/auth";

export default function Registration() {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [passwordConfirmation, setPasswordConfirmation] = useState("");
  const [errors, setErrors] = useState<Record<string, string[]>>({});
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setErrors({});

    const response = await fetch("/api/auth/register", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        username,
        password,
        password_confirmation: passwordConfirmation,
      }),
    });

    const data: AuthResponse = await response.json();

    if (data.success) {
      router.visit("/auth/recovery-codes?first_time=true");
    } else {
      setErrors(data.errors || {});
      setLoading(false);
    }
  }

  return (
    <div>
      <h1>Create Account</h1>

      <form onSubmit={handleSubmit}>
        <div>
          <label htmlFor="username">Username</label>
          <input
            id="username"
            type="text"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            pattern="[a-zA-Z0-9_]{3,30}"
            title="3-30 characters, letters, numbers, underscore only"
            required
            autoComplete="username"
          />
          {errors.username && <span>{errors.username.join(", ")}</span>}
        </div>

        <div>
          <label htmlFor="password">Password</label>
          <input
            id="password"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            minLength={8}
            required
            autoComplete="new-password"
          />
          {errors.password && <span>{errors.password.join(", ")}</span>}
        </div>

        <div>
          <label htmlFor="password_confirmation">Confirm Password</label>
          <input
            id="password_confirmation"
            type="password"
            value={passwordConfirmation}
            onChange={(e) => setPasswordConfirmation(e.target.value)}
            required
            autoComplete="new-password"
          />
          {errors.password_confirmation && (
            <span>{errors.password_confirmation.join(", ")}</span>
          )}
        </div>

        {errors.base && <div>{errors.base.join(", ")}</div>}

        <button type="submit" disabled={loading}>
          {loading ? "Creating account..." : "Create Account"}
        </button>
      </form>

      <p>
        Already have an account? <a href="/auth/sign-in">Sign In</a>
      </p>
    </div>
  );
}
