# Security

## TLS certificate checks (Android)

The Rust HTTP client (`src/android/tls.rs`) checks server certificates with:

- **Host name:** rustls (`verify_server_name`).
- **Chain:** Android's default trust manager (`TlsVerifier.kt`): system and
  user CAs (`res/xml/network_security_config.xml`), expiry, and the system's
  built-in blocklist of compromised keys. CA distrust comes with Android's
  Conscrypt/CA store updates.
- **No online revocation check** (OCSP / CRL download).

### Why no revocation check

rustls-platform-verifier, reqwest's default, downloads CRLs over HTTP during
the first handshakes of each process: 1–2 s before the first server response
at every cold start. Its check is soft-fail: if the download fails, the
certificate is accepted, so an attacker who can intercept the connection can
also block the download. Let's Encrypt no longer runs OCSP, so CRLs are the
only online source. Android's own HTTPS stack does not check revocation either.

### Risk accepted

A revoked but unexpired certificate for the homeserver stays trusted. To use
it, an attacker needs its private key and a position on the network path.
They could then impersonate the homeserver and capture the access token:
account access until that session is signed out, plus unencrypted rooms and
metadata. End-to-end encrypted messages stay protected (device keys, cross-signing).

The exposure ends when the certificate expires (Let's Encrypt: at most 90 days,
shorter certificates available).

Desktop uses rustls-platform-verifier unchanged.
