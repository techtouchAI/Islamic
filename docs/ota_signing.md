# OTA signing key provisioning

The in-app installer is disabled unless its Ed25519 public key is embedded at
build time. Never commit the private key or send it via chat.

A repository owner generates an Ed25519 key pair on a trusted machine:

```sh
openssl genpkey -algorithm Ed25519 -out ota-signing.pem
```

Add the **private PEM** to the GitHub Actions repository secret
`OTA_MANIFEST_SIGNING_KEY` using the GitHub UI (Settings → Secrets and
variables → Actions). Protect access to the secret and retain an encrypted
backup outside the repository. Only the release workflow reads it; the workflow
injects the corresponding public key into the APK, signs the APK URL, digest,
version, and minimum supported build, then uploads the manifest with the APK.

Optionally set the Actions **variable** `OTA_MIN_SUPPORTED_BUILD` to the oldest
permitted build (an integer not greater than the release build number). The
default is 0, which leaves updates optional. Rotate the key only with a staged
rollout that accepts the previous verification key until old clients have
upgraded. Do not remove the older update path before that rollout succeeds.

Without a provisioned signing secret, the installer is disabled. The app must
never redirect to an unsigned release or claim it has a verified update.
