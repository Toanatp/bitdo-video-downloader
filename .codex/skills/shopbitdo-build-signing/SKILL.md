---
name: shopbitdo-build-signing
description: Use when building or releasing Bitdo Downloader on Windows so generated artifacts are signed with the shopbitdo Authenticode certificate and public trust certificates stay bundled.
---

# shopbitdo Build Signing

Use this local project skill whenever a task builds, releases, uploads, or verifies Bitdo Downloader Windows artifacts.

## Required behavior

- Run `pnpm tauri:build` for normal Windows release builds. This project script builds the Tauri app and then signs the Windows artifacts.
- Use `pnpm tauri:build:raw` only when explicitly debugging the unsigned Tauri build output.
- After any build that produces `.exe`, `.msi`, or `.dll` files under `src-tauri/target/release`, run `pnpm sign:windows` before publishing or uploading artifacts.
- Verify signing succeeds before reporting that a build is ready for release.

## Signing toolkit

The build/signing machine uses the established local toolkit at:

```text
C:\Users\vungb\shopbitdo-internal-code-signing
```

The project scripts call these toolkit scripts:

- `create_shopbitdo_certificates.ps1`
- `install_shopbitdo_certificate.ps1`
- `sign_app.ps1`
- `verify_signature.ps1`

## Commands

```powershell
npm run signing:prepare
npm run tauri:build
npm run sign:windows
npm run trust:install
```

`npm run signing:prepare` creates or reuses the shopbitdo certificate pair, trusts the public certificates for the current Windows user, and copies only public `.cer` files into `src-tauri/certs`.

`npm run tauri:build` runs `scripts/build-signed.ps1`, so the expected release path is already build-and-sign.

`npm run sign:windows` signs existing build artifacts again after a rebuild or repack.

`npm run trust:install` installs the bundled public certificates for the current user as a non-admin test. Employee or production machines should use elevated `LocalMachine` trust installation through `scripts/install-shopbitdo-public-certs.ps1`.

## Security rules

- Never commit `shopbitdo-code-signing.pfx`, `.p12`, private keys, passwords, or DPAPI password files.
- Never copy the PFX/private key to user machines.
- User machines receive only:
  - `shopbitdo-root.cer`
  - `shopbitdo-code-signing.cer`
  - `shopbitdo-certificates.json`
- Tauri updater signing keys and Windows Authenticode certificates are separate systems. Do not replace one with the other.

## Release checklist

Before uploading a GitHub Release asset, confirm:

1. `npm run tauri:build` completed successfully.
2. `scripts/sign-windows-build.ps1` signed and verified all Windows artifacts.
3. The release asset is one of the signed final artifacts, not an intermediate unsigned file.
4. `src-tauri/certs` contains only public certificate files and metadata.
