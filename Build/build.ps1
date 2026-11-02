# ==============================================================================
# Filename: build.ps1
# Version:  0.1.0 | Updated: 2026-05-20
# Author:   johnsarie27
# ==============================================================================

[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet(
        'Default',
        'Init',
        'Setup',
        'CombineFunctionsAndStage',
        'ImportStagingModule',
        'Analyze',
        'Test',
        'CreateBuildArtifact',
        'Cleanup'
    )]
    [System.String[]] $TaskList = 'Default',

    [Parameter()]
    [System.Collections.Hashtable] $Parameters,

    [Parameter()]
    [System.Collections.Hashtable] $Properties,

    [Parameter()]
    [System.Management.Automation.SwitchParameter] $ResolveDependency
)

Set-StrictMode -Version Latest

$nl = [System.Environment]::NewLine

Write-Output -InputObject ('{0}STARTED TASKS: {1}{0}' -f $nl, ($TaskList -join ','))

Write-Output -InputObject ('{0}PowerShell Version Information:' -f $nl)
$PSVersionTable

# RESOLVE DEPENDENCIES VIA PSRESOURCEGET
if ($PSBoundParameters.Keys -contains 'ResolveDependency') {
    $dependencyConfigPath = Join-Path -Path $PSScriptRoot -ChildPath 'depend.psd1'
    Write-Output -InputObject ('Checking / resolving module dependencies from [{0}]...' -f $dependencyConfigPath)

    $dependencyData = Import-PowerShellDataFile -Path $dependencyConfigPath
    $dependencyNames = @($dependencyData.Keys | Where-Object { $_ -ne 'PSDependOptions' })
    foreach ($name in $dependencyNames) {
        # TrustRepository: PSGallery registers as untrusted under PSResourceGet, so the install would prompt.
        $installPSResourceParams = @{
            Name            = $name
            Version         = $dependencyData[$name]
            Repository      = 'PSGallery'
            TrustRepository = $true
            Scope           = 'CurrentUser'
            ErrorAction     = 'Stop'
        }
        Install-PSResource @installPSResourceParams
    }

    # Install-PSResource is silent; list installed versions so the resolved pins are visible in the log.
    Get-InstalledPSResource -Name $dependencyNames | Sort-Object -Property 'Name', 'Version' | ForEach-Object {
        Write-Output -InputObject ('Resolved dependency: {0} {1}' -f $_.Name, $_.Version)
    }

    $PSBoundParameters.Remove('ResolveDependency') | Out-Null
}
else {
    Write-Output -InputObject ('{0}Skipping dependency check...{0}' -f $nl)
}

# BUILD ENVIRONMENT VARIABLES
$env:BHProjectPath = $PSScriptRoot | Split-Path -Parent
$manifestFile = Get-ChildItem -Path $env:BHProjectPath -Filter '*.psd1' | Select-Object -First 1
$env:BHProjectName = $manifestFile.BaseName
$env:BHPSModuleManifest = $manifestFile.FullName

# INVOKE PSAKE
$invokePsakeParams = @{
    buildFile = Join-Path -Path $env:BHProjectPath -ChildPath 'Build\build.psake.ps1'
    nologo    = $true
}
Invoke-psake @invokePsakeParams @PSBoundParameters

Write-Output -InputObject ('{0}FINISHED TASKS: {1}' -f $nl, ($TaskList -join ','))
exit ( [System.Int32](-not $psake.build_success) )
