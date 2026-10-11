# ==============================================================================
# Filename: build.psake.ps1
# Version:  0.1.1 | Updated: 2026-10-11
# Author:   johnsarie27
# ==============================================================================

Properties {
    $ProjectRoot = $env:BHProjectPath
    if (-not $ProjectRoot) {
        $ProjectRoot = $PSScriptRoot | Split-Path -Parent
    }

    $Timestamp = Get-Date -UFormat '%Y%m%d-%H%M%S'
    $PSVersion = $PSVersionTable.PSVersion.Major
    $lines = '----------------------------------------------------------------------'

    # PESTER
    $TestScripts = Get-ChildItem -Path "$ProjectRoot/Tests/*/*.Tests.ps1" -ErrorAction Ignore
    $TestFile = 'Test-Unit_{0}.xml' -f $Timestamp

    # SCRIPT ANALYZER
    [ValidateSet('Error', 'Warning', 'Any', 'None')]
    $ScriptAnalysisFailBuildOnSeverityLevel = 'Error'
    $ScriptAnalyzerSettingsPath = '{0}/Build/PSScriptAnalyzerSettings.psd1' -f $ProjectRoot

    # BUILD
    $ArtifactFolder = Join-Path -Path $ProjectRoot -ChildPath 'Artifacts'

    # STAGING
    $StagingFolder = Join-Path -Path $ProjectRoot -ChildPath 'Staging'
    $StagingModulePath = Join-Path -Path $StagingFolder -ChildPath $env:BHProjectName
    $StagingModuleManifestPath = Join-Path -Path $StagingModulePath -ChildPath ('{0}.psd1' -f $env:BHProjectName)
}

#region TASKS ==================================================================

Task 'Default' -depends 'Test'

# SHOW BUILD VARIABLES
Task 'Init' {
    $lines

    Set-Location -Path $ProjectRoot
    'Build System Details:'
    Get-Item -Path ENV:BH*
    ''
}

# SETUP ARTIFACT AND STAGING FOLDERS
Task 'Setup' -depends 'Init' {
    $lines

    $foldersToSetup = @($ArtifactFolder, $StagingFolder)

    foreach ($folderPath in $foldersToSetup) {
        Remove-Item -Path $folderPath -Recurse -Force -ErrorAction 'SilentlyContinue'
        New-Item -Path $folderPath -ItemType 'Directory' -Force | Out-String | Write-Verbose
    }
}

# STAGE MODULE FILES
Task 'CombineFunctionsAndStage' -depends 'Setup' {
    $lines

    New-Item -Path $StagingFolder -ItemType 'Directory' -Force | Out-String | Write-Verbose
    New-Item -Path $StagingModulePath -ItemType 'Directory' -Force | Out-String | Write-Verbose

    # COPY ONLY SHIPPING FILES INTO STAGING
    $pathsToCopy = @(
        Join-Path -Path $ProjectRoot -ChildPath 'Private'
        Join-Path -Path $ProjectRoot -ChildPath 'Public'
        Join-Path -Path $ProjectRoot -ChildPath 'README.md'
        Join-Path -Path $ProjectRoot -ChildPath ('{0}.psd1' -f $env:BHProjectName)
        Join-Path -Path $ProjectRoot -ChildPath ('{0}.psm1' -f $env:BHProjectName)
    )

    foreach ($path in $pathsToCopy) {
        Copy-Item -Path $path -Destination $StagingModulePath -Recurse -Force
    }
}

# IMPORT STAGED MODULE
Task 'ImportStagingModule' -depends 'Init', 'CombineFunctionsAndStage' {
    $lines
    Write-Output -InputObject ('Reloading staged module from path: [{0}]' -f $StagingModulePath)

    if (Get-Module -Name $env:BHProjectName) {
        Remove-Module -Name $env:BHProjectName -Force
    }
    Import-Module -Name $StagingModulePath -ErrorAction 'Stop' -Force
}

# RUN PSSCRIPTANALYZER
Task 'Analyze' -depends 'ImportStagingModule' {
    $lines
    Write-Output -InputObject ('Running PSScriptAnalyzer on path: [{0}]' -f $StagingModulePath)

    $analyzeParams = @{
        Path     = $StagingModulePath
        Recurse  = $true
        Settings = $ScriptAnalyzerSettingsPath
        Verbose  = $VerbosePreference
    }
    $Results = Invoke-ScriptAnalyzer @analyzeParams
    $Results | Select-Object -Property 'RuleName', 'Severity', 'ScriptName', 'Line', 'Message' | Format-List

    switch ($ScriptAnalysisFailBuildOnSeverityLevel) {
        'None' {
            return
        }
        'Error' {
            Assert -conditionToCheck (
                ($Results | Where-Object -FilterScript { $_.Severity -eq 'Error' }).Count -eq 0
            ) -failureMessage 'One or more ScriptAnalyzer errors were found. Build cannot continue!'
        }
        'Warning' {
            Assert -conditionToCheck (
                ($Results | Where-Object -FilterScript {
                    $_.Severity -eq 'Warning' -or $_.Severity -eq 'Error'
                }).Count -eq 0
            ) -failureMessage 'One or more ScriptAnalyzer warnings were found. Build cannot continue!'
        }
        default {
            Assert -conditionToCheck ($Results.Count -eq 0) -failureMessage 'One or more ScriptAnalyzer issues were found. Build cannot continue!'
        }
    }
}

# RUN PESTER TESTS
Task 'Test' -depends 'ImportStagingModule' {
    $lines

    if (-not $TestScripts) {
        Write-Warning -Message 'No test scripts found under Tests/*/*.Tests.ps1; skipping.'
        return
    }

    $TestFilePath = Join-Path -Path $ArtifactFolder -ChildPath $TestFile

    $PesterConfig = New-PesterConfiguration
    $PesterConfig.TestResult.OutputFormat = 'JUnitXml'
    $PesterConfig.TestResult.OutputPath = $TestFilePath
    $PesterConfig.TestResult.Enabled = $true
    $PesterConfig.Run.PassThru = $true
    $PesterConfig.Run.Path = $TestScripts.FullName

    $TestResults = Invoke-Pester -Configuration $PesterConfig

    # Fail build on any non-passing result. Discovery errors attach to the
    # container rather than a test, leaving FailedCount at 0.
    if ($TestResults.Result -ne 'Passed') {
        Write-Error -Message ("Pester result '{0}' with [{1}] failed test(s), build failed" -f $TestResults.Result, $TestResults.FailedCount) -ErrorAction Stop
    }
}

# CREATE ZIP ARTIFACT
Task 'CreateBuildArtifact' -depends 'Init', 'CombineFunctionsAndStage' {
    $lines

    New-Item -Path $ArtifactFolder -ItemType 'Directory' -Force | Out-String | Write-Verbose

    try {
        $manifest = Test-ModuleManifest -Path $StagingModuleManifestPath -ErrorAction 'Stop'
        [System.Version] $manifestVersion = $manifest.Version
    }
    catch {
        Write-Error -Message ('Could not get manifest version from [{0}]' -f $StagingModuleManifestPath) -ErrorAction Stop
    }

    try {
        $releaseFilename = '{0}-v{1}.zip' -f $env:BHProjectName, $manifestVersion.ToString()
        $releasePath = Join-Path -Path $ArtifactFolder -ChildPath $releaseFilename
        Write-Output -InputObject ('Creating release artifact [{0}] using manifest version [{1}]' -f $releasePath, $manifestVersion)

        $compressParams = @{
            Path            = '{0}/*' -f $StagingFolder
            DestinationPath = $releasePath
            Force           = $true
            Verbose         = $VerbosePreference
            ErrorAction     = 'Stop'
        }
        Compress-Archive @compressParams
    }
    catch {
        Write-Error -Message ('Could not create release artifact [{0}] using manifest version [{1}]' -f $releasePath, $manifestVersion) -ErrorAction Stop
    }

    Write-Output -InputObject 'FINISHED: Release artifact creation.'
}

# CLEAN UP STAGING + ARTIFACTS
Task 'Cleanup' {
    $lines
    Write-Output -InputObject 'Cleaning leftover/unneeded artifacts'

    Remove-Item -Path $ArtifactFolder -Recurse -Force -ErrorAction 'SilentlyContinue'
    Remove-Item -Path $StagingFolder -Recurse -Force -ErrorAction 'SilentlyContinue'
}

#endregion =====================================================================
