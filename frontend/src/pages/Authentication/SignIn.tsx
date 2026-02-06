import { useState, FormEvent } from "react";
import { router } from "@inertiajs/react";
import type { AuthPageProps, AuthResponse } from "@/types/auth";

interface Props extends AuthPageProps {
  registration_enabled?: boolean;
}

export default function SignIn({ registration_enabled = true }: Props) {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [errors, setErrors] = useState<Record<string, string[]>>({});
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setErrors({});

    const response = await fetch("/api/auth/sign-in", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username, password }),
    });

    const data: AuthResponse = await response.json();

    if (data.success) {
      router.visit("/");
    } else {
      setErrors(data.errors || {});
      setLoading(false);
    }
  }

  async function handleAnonymous() {
    setLoading(true);
    setErrors({});

    const response = await fetch("/api/auth/anonymous", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
    });

    const data: AuthResponse = await response.json();

    if (data.success) {
      router.visit("/");
    } else {
      setErrors(data.errors || {});
      setLoading(false);
    }
  }

  return (
    <div>
      <h1>Sign In</h1>

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
          {errors.username && <span>{errors.username.join(", ")}</span>}
        </div>

        <div>
          <label htmlFor="password">Password</label>
          <input
            id="password"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
            autoComplete="current-password"
          />
          {errors.password && <span>{errors.password.join(", ")}</span>}
        </div>

        {errors.base && <div>{errors.base.join(", ")}</div>}

        <button type="submit" disabled={loading}>
          {loading ? "Signing in..." : "Sign In"}
        </button>
      </form>

      <div>
        <button type="button" onClick={handleAnonymous} disabled={loading}>
          Continue as Anonymous
        </button>
      </div>

      {registration_enabled && (
        <p>
          Don&apos;t have an account?{" "}
          <a href="/auth/registration/new">Register</a>
        </p>
      )}

      <p>
        <a href="/auth/reset-password">Forgot password?</a>
      </p>
    </div>
  );
}
