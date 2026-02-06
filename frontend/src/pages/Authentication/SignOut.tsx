import { useState } from "react";
import { router } from "@inertiajs/react";
export default function SignOut() {
  const [loading, setLoading] = useState(false);

  async function handleSignOut() {
    setLoading(true);

    await fetch("/api/auth/session", {
      method: "DELETE",
    });

    router.visit("/");
  }

  return (
    <div>
      <h1>Sign Out</h1>
      <p>Are you sure you want to sign out?</p>

      <div>
        <button type="button" onClick={handleSignOut} disabled={loading}>
          {loading ? "Signing out..." : "Sign Out"}
        </button>
        <a href="/">Cancel</a>
      </div>
    </div>
  );
}
