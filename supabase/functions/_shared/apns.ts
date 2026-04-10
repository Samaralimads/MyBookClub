// supabase/functions/_shared/apns.ts
// Shared APNs helper — imported by all notification Edge Functions

export async function sendPush(
  apnsToken: string,
  title: string,
  body: string,
  data?: Record<string, string>,
): Promise<void> {
  const bundleId = Deno.env.get("APNS_BUNDLE_ID")!;
  const apnsKey = Deno.env.get("APNS_PRIVATE_KEY")!;
  const apnsKeyId = Deno.env.get("APNS_KEY_ID")!;
  const apnsTeamId = Deno.env.get("APNS_TEAM_ID")!;
  const apnsEnv = Deno.env.get("APNS_ENV") ?? "production";

  const apnsHost = apnsEnv === "sandbox"
    ? "api.sandbox.push.apple.com"
    : "api.push.apple.com";

  // Build JWT
  const jwtHeader = btoa(JSON.stringify({ alg: "ES256", kid: apnsKeyId }));
  const now = Math.floor(Date.now() / 1000);
  const jwtPayload = btoa(JSON.stringify({ iss: apnsTeamId, iat: now }));

  const keyData = apnsKey
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0)),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );

  const signingInput = `${jwtHeader}.${jwtPayload}`;
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    cryptoKey,
    new TextEncoder().encode(signingInput),
  );

  const jwt = `${signingInput}.${btoa(String.fromCharCode(...new Uint8Array(signature)))}`;

  const notification = {
    aps: {
      alert: { title, body },
      sound: "default",
      badge: 1,
    },
    ...data,
  };

  const resp = await fetch(`https://${apnsHost}/3/device/${apnsToken}`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      authorization: `bearer ${jwt}`,
      "apns-topic": bundleId,
      "apns-push-type": "alert",
      "apns-priority": "10",
    },
    body: JSON.stringify(notification),
  });

  if (!resp.ok) {
    const err = await resp.text();
    console.error("APNs error:", resp.status, err);
  }
}
