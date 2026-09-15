# Contributing to PS.DCU

Thanks for your interest in improving PS.DCU.

## Repository layout

- `PS.DCU.psd1`, `PS.DCU.psm1` — module manifest and root module (repo root)
- `Public/` — exported functions, one per file, filename matches function name
- `Private/` — internal helpers, not exported
- `Tests/Common/` — Pester tests run by the build pipeline
- `Build/` — psake build pipeline and dependency manifest
- `docs/` — design notes (not shipped in the published module)

## Prerequisites

- Windows PowerShell 5.1 or PowerShell 7.4+
- Admin rights for `Install-DCUUpdate` / `Set-DCUConfiguration` smoke tests
- A Dell host with [Dell Command Update](https://www.dell.com/support/kbdoc/en-us/000177325/dell-command-update) installed for end-to-end testing

## Build and test

The build pipeline mirrors the [`SecurityTools`](https://github.com/jjohns-dev/SecurityTools) module:

```powershell
# One-time: install build dependencies (Pester, psake, PSScriptAnalyzer)
./Build/build.ps1 -ResolveDependency -TaskList Init

# Static analysis
./Build/build.ps1 -TaskList Analyze

# Run Pester tests
./Build/build.ps1 -TaskList Test

# Stage + analyze + test + zip the published artifact
./Build/build.ps1 -TaskList CreateBuildArtifact
```

The `CreateBuildArtifact` task assembles a clean `Staging/PS.DCU/` directory (only `Public/`, `Private/`, `README.md`, `.psd1`, `.psm1`) and zips it to `Artifacts/PS.DCU-v<version>.zip`. `Build/`, `Tests/`, `docs/`, `.github/`, `.vscode/` are intentionally excluded from the artifact.

## Coding standards

- One function per file under `Public/`; filename must match function name.
- `[CmdletBinding()]` on every function; full comment-based help.
- Full .NET type names (`[System.String]`, not `[string]`).
- Single-quoted strings; use the `-f` operator for interpolation.
- Splat cmdlet calls with 2+ parameters.
- Approved verbs only (`Get-Verb`).
- UTF-8 without BOM, 4-space indentation, no tabs.

## Pull requests

1. Bump `ModuleVersion` in `PS.DCU.psd1` per semver (Major: new capability set; Minor: new functions; Build: bug fixes).
2. Add or update Pester tests under `Tests/`.
3. Ensure `./Build/build.ps1 -TaskList Analyze,Test` passes locally.
4. Update `README.md` examples if the public surface changed.
