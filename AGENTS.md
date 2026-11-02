# AGENTS.md - repo conventions for `PS.DCU`

Context for an AI agent (or a human working alongside one) to work productively in this repo. Cross-repo CI conventions (floors, pinning, help-test reasoning) live in [`docs/shared-ci-standards.md`](https://github.com/jjohns-dev/pwsh-module-ci/blob/main/docs/shared-ci-standards.md) in `jjohns-dev/pwsh-module-ci`; this file records only what is true here.

## Purpose

`PS.DCU` wraps the Dell Command Update CLI, `dcu-cli.exe`. The module looks for it only under `C:\Program Files\Dell\CommandUpdate\` and `C:\Program Files (x86)\Dell\CommandUpdate\` (`PS.DCU.psm1`), so it is a Windows-only module in practice. Exported functions and usage are in the [README](README.md).

## Layout

| Path | Contents |
| ---- | -------- |
| `Public/` | Exported functions, one per file, filename matches function name |
| `Private/` | Internal helpers; `Invoke-DCU` launches `dcu-cli.exe`, `Get-DCUExecutable` locates it |
| `PS.DCU.psm1` | Loader, plus module constants: install paths, report path, exit-code map, export list |
| `PS.DCU.psd1` | Module manifest |
| `Tests/Common/` | `Help`, `Manifest` and `Meta` tests; the build collects `Tests/*/*.Tests.ps1` |
| `Build/` | `build.ps1` -> `build.psake.ps1` (psake), `depend.psd1` pins, PSScriptAnalyzer settings |
| `.github/workflows/` | `ci.yml`, `pssa-sarif.yml`, `release.yml`, all calling `jjohns-dev/pwsh-module-ci` reusable workflows `@v1` |

## Working conventions

- Coding standards and the PR checklist are in [CONTRIBUTING.md](CONTRIBUTING.md).
- Build sequence, as CI runs it: `./Build/build.ps1 -ResolveDependency -TaskList Init`, then `-TaskList CombineFunctionsAndStage`, `Analyze`, `Test`. Pester writes JUnit XML to `Artifacts/Test-Unit_<timestamp>.xml`.
- `-ResolveDependency` installs each module in `Build/depend.psd1` with `Install-PSResource` at its exact pinned version (CurrentUser scope), skipping the `PSDependOptions` key, then logs one `Resolved dependency: <name> <version>` line per installed version. PSDepend is no longer used; `depend.psd1` keeps its shape.
- Merging: squash only, signed commits required, the remote branch auto-deletes. The required status check is strict, so a PR branch must be up to date with `main` before it can merge.

## CI is Windows-only, deliberately

`ci.yml` passes `os-matrix: '["windows-latest"]'` rather than the fleet default of ubuntu, windows and macos. The module wraps a Dell utility it only looks for under Windows install paths, so running it on another OS asserts nothing. Do not "restore" the default matrix.

## The required check is pinned in a ruleset

`main` has no classic branch protection (`GET /repos/jjohns-dev/PS.DCU/branches/main/protection` returns 404). It is protected by repository ruleset `22407813`, whose `required_status_checks` rule names exactly one context: `validate / validate (windows-latest)`.

That context name comes from `os-matrix`. **Changing `os-matrix` renames the required check**, so the ruleset must be edited in lockstep, by the repo owner. Otherwise `main` requires a check that nothing produces and no PR can merge. This happened once, in #16: the ruleset was switched from `(ubuntu-latest)` to `(windows-latest)` first, and until the matrix change merged no other PR against `main` could merge.

## Gotchas that have bitten here

- **`Tests/Common/Help.Tests.ps1`'s parameter check loops inside a single `It`, on purpose.** `Describe -ForEach` runs once per exported command, but `It 'documents every parameter'` gathers the parameter list at run time and loops with `foreach` inside one `It`. Nothing per-parameter is bound at discovery, so it cannot hit the discovery-binding defect fixed elsewhere in the fleet. Do not "modernise" it to a per-parameter `It -ForEach`. Background: #16.
- **PowerShell Gallery 403 during dependency resolution.** Seen once, 2026-11-02, PR #17 on ubuntu: `Install-PSResource` failed with `Response status code does not indicate success: 403 (Forbidden)` on the gallery lookup for Pester 6.2.0. `Find-PSResource` for the same version succeeded from a workstation, and re-running the failed job passed. Cause unconfirmed. If it recurs, record it here before re-running.
