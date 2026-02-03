Configure upload via API (Bitrise)

This repo contains helper scripts to perform the 3-step upload flow described by Bitrise:

1) Request an upload URL
2) Upload the file to the returned pre-signed URL (PUT)
3) Query the artifact status

Files added:
- `scripts/upload-bitrise.ps1` — PowerShell script for Windows/PowerShell
- `scripts/upload-bitrise.sh` — Bash script for macOS / Linux

PowerShell usage (Windows PowerShell / PowerShell Core):

```powershell
# Example
.
"scripts/upload-bitrise.ps1" -AuthToken "<AUTH_TOKEN>" -FilePath "C:\path\to\file.ipa" -ArtifactUUID "<NEW_ARTIFACT_UUID>"
```

Bash usage (macOS / Linux):

```bash
# Requires: curl, jq, python3
./scripts/upload-bitrise.sh "<AUTH_TOKEN>" "/path/to/file.ipa" "<NEW_ARTIFACT_UUID>"
```

Notes and dependencies:
- The scripts expect the full `Authorization` header value as in `Authorization: <AUTH_TOKEN>` (if Bitrise expects `Bearer <token>`, include the `Bearer` prefix in the argument).
- The Bash script requires `jq` and `python3` for JSON parsing and URL-encoding. Install via your package manager if missing.
- The PowerShell script uses `Invoke-RestMethod`; it will print JSON responses.

Replace the placeholders `<AUTH_TOKEN>`, `<NEW_ARTIFACT_UUID>`, and file paths with real values.

If you want, I can:
- Commit these files to a Git branch and run a quick local smoke-check (no network calls will be made).
- Add a version that uses raw `curl` on Windows (if you prefer `curl.exe`).
