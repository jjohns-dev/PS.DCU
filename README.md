# PS.DCU

[![ci](https://github.com/jjohns-dev/PS.DCU/actions/workflows/ci.yml/badge.svg)](https://github.com/jjohns-dev/PS.DCU/actions/workflows/ci.yml)
[![release](https://github.com/jjohns-dev/PS.DCU/actions/workflows/release.yml/badge.svg)](https://github.com/jjohns-dev/PS.DCU/actions/workflows/release.yml)

PowerShell module that wraps the Dell Command Update CLI (`dcu-cli.exe`).

## Requirements

- Windows PowerShell 5.1 or PowerShell 7.4+
- [Dell Command Update](https://www.dell.com/support/kbdoc/en-us/000177325/dell-command-update) installed on the local host
- Administrator rights for `Install-DCUUpdate` and `Set-DCUConfiguration`

## Install

From the repo root, after building:

```powershell
./Build/build.ps1 -TaskList CreateBuildArtifact
Expand-Archive -Path ./Artifacts/PS.DCU-v*.zip -DestinationPath "$env:USERPROFILE\Documents\PowerShell\Modules"
Import-Module PS.DCU
```

## Exported functions

| Function | Purpose |
|---|---|
| `Get-DCUVersion` | Return the installed Dell Command Update version and executable path |
| `Get-DCUUpdate` | Scan for applicable updates; optionally filter by name, type, severity, or device category |
| `Install-DCUUpdate` | Apply updates (accepts pipeline input from `Get-DCUUpdate`); supports `-WhatIf` |
| `Invoke-DCUScan` | Run a scan and return the report path plus exit-code metadata |
| `Get-DCUReport` | Parse existing DCU XML reports into objects |
| `Get-DCUDriverHistory` | Return previously installed driver/firmware updates |
| `Get-DCUConfiguration` | Export and parse the current DCU configuration |
| `Set-DCUConfiguration` | Configure DCU policy (schedule, notifications, deferrals, lock) |

## Usage

```powershell
# List all available updates
Get-DCUUpdate

# Filter to security updates only
Get-DCUUpdate -Severity 'security'

# Install all critical and security updates, with auto reboot
Get-DCUUpdate -Severity 'security', 'critical' | Install-DCUUpdate -Reboot -Confirm:$false

# Export current configuration
Get-DCUConfiguration

# Set weekly schedule and lock settings
Set-DCUConfiguration -ScheduleWeekly 'Sunday' -ScheduleTime '03:00' -LockSettings 'Enable'
```

## Releases

Releases are cut by pushing a semver tag matching `v[0-9].[0-9]+.[0-9]+`:

```powershell
git tag v0.1.0
git push origin v0.1.0
```

This triggers [.github/workflows/release.yml](.github/workflows/release.yml), which stages the module, runs PSScriptAnalyzer and Pester, builds the zip via `CreateBuildArtifact`, and publishes a GitHub Release with auto-generated notes and the artifact attached.

Pull requests are validated by [.github/workflows/validate.yml](.github/workflows/validate.yml) (Init → Stage → Analyze → Test).

## License

MIT — see [LICENSE](LICENSE).
