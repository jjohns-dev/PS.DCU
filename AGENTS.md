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
| `Tests/Common/` | `help` tests only; the build collects `Tests/*/*.tests.ps1`. Manifest and encoding checks come from the harness's [shared suites](https://github.com/jjohns-dev/pwsh-module-ci/blob/main/docs/consumer-guide.md#shared-tests) |
| `Build/` | `build.ps1`, the shim for the shared [`pwsh-module-ci` harness](https://github.com/jjohns-dev/pwsh-module-ci/blob/main/docs/consumer-guide.md) (copied from its template, do not edit), and [`harness.psd1`](https://github.com/jjohns-dev/pwsh-module-ci/blob/main/docs/consumer-guide.md#buildharnesspsd1), whose `PesterStrictMode = $true` runs the tests under `Set-StrictMode -Version Latest` |
| `.github/workflows/` | `ci.yml`, `pssa-sarif.yml`, `release.yml`, all calling `jjohns-dev/pwsh-module-ci` reusable workflows `@v2` |

## Working conventions

- Coding standards and the PR checklist are in [CONTRIBUTING.md](CONTRIBUTING.md).
- Build sequence, as CI runs it: `./Build/build.ps1 -ResolveDependency -TaskList Init`, then `-TaskList CombineFunctionsAndStage`, `Analyze`, `Test`. Pester writes JUnit XML to `Artifacts/Test-Unit_<timestamp>.xml`.
- `-ResolveDependency` installs the harness's pinned build tools (Pester, psake, PSScriptAnalyzer) plus any modules in the manifest's `RequiredModules` (none today), then logs one `Resolved dependency: <name> <version>` line per module. See the consumer guide's [Dependencies](https://github.com/jjohns-dev/pwsh-module-ci/blob/main/docs/consumer-guide.md#dependencies) section.
- Merging: squash only, signed commits required, the remote branch auto-deletes. The required status check is strict, so a PR branch must be up to date with `main` before it can merge.

## CI is Windows-only, deliberately

`ci.yml` passes `os-matrix: '["windows-latest"]'` rather than the fleet default of ubuntu, windows and macos. The module only runs on Windows (it looks for `dcu-cli.exe` only under Windows install paths), so CI matches the target platform. The suite is currently metadata-only (help, manifest and style checks) and exercises no Windows-coupled code on any OS; that gap is tracked in #20. Do not "restore" the default matrix.

## The required check is pinned in a ruleset

`main` has no classic branch protection (`GET /repos/jjohns-dev/PS.DCU/branches/main/protection` returns 404). It is protected by repository ruleset `22407813`, whose `required_status_checks` rule names exactly one context: `validate / validate (windows-latest)`.

That context name comes from `os-matrix`. **Changing `os-matrix` renames the required check**, so the ruleset must be edited in lockstep, by the repo owner. Otherwise `main` requires a check that nothing produces and no PR can merge. This happened once, in #16: the ruleset was switched from `(ubuntu-latest)` to `(windows-latest)` first, and until the matrix change merged no other PR against `main` could merge.

## Gotchas that have bitten here

- **`Tests/Common/help.tests.ps1`'s parameter check loops inside a single `It`, on purpose.** `Describe -ForEach` runs once per exported command, but `It 'documents every parameter'` gathers the parameter list at run time and loops with `foreach` inside one `It`. Nothing per-parameter is bound at discovery, so it cannot hit the discovery-binding defect fixed elsewhere in the fleet. Do not "modernise" it to a per-parameter `It -ForEach`. Both checks inside the loop read help-documented parameter names from the AST, not `Get-Help`, because `Get-Help` synthesizes entries for undocumented parameters (next note). Background: #16.
- **In `help.tests.ps1`, help-documented parameter names come from the AST, for both halves of `documents every parameter`; everything else comes from `Get-Help`. This is deliberate.** `Get-Help` synthesizes a parameter entry for every declared parameter, including one with no `.PARAMETER` block, and silently drops a `.PARAMETER` block that names no real parameter. Checking either direction against `Get-Help` therefore compares a list with the filter that produced it and can never fail. Both halves read `$command.ScriptBlock.Ast.GetHelpContent().Parameters.Keys` (uppercased; `Should -Contain` is case-insensitive), guarded for a `$null` result so the line is safe under strict mode. Do not "tidy" either half to `Get-Help`. The stale-help half was mutation-proved in #21 (run `41481360254`) by adding a bogus `.PARAMETER` block; the missing-help half was found to be a tautology, and both halves were mutation-proved, under #23.
- **The `min-tests` floor does not guard the stale-help assertion.** The floor counts `testcase` nodes, and the assertion added in #21 loops inside the existing `It 'documents every parameter'` without producing a case of its own; the collected count was unchanged by #21. Deleting that assertion would leave the count unchanged and the floor silent. That is the cost of the deliberate run-time loop above, not a defect to restructure away: a green floor means the suite still collects, not that this check is still present.
- **PowerShell Gallery 403 during dependency resolution.** Seen once, 2026-11-02, PR #17 on ubuntu: `Install-PSResource` failed with `Response status code does not indicate success: 403 (Forbidden)` on the gallery lookup for Pester 6.2.0. `Find-PSResource` for the same version succeeded from a workstation, and re-running the failed job passed. Cause unconfirmed. If it recurs, record it here before re-running.
