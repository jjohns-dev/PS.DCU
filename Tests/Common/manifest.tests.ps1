# ==============================================================================
# Filename: Manifest.Tests.ps1
# Version:  0.1.0 | Updated: 2026-05-20
# Author:   johnsarie27
# ==============================================================================

BeforeDiscovery {
    $script:projectRoot = Split-Path -Path $PSScriptRoot -Parent | Split-Path -Parent
    $script:moduleName = (Get-ChildItem -Path $script:projectRoot -Filter '*.psd1' | Select-Object -First 1).BaseName
    $script:manifestPath = Join-Path -Path $script:projectRoot -ChildPath ('{0}.psd1' -f $script:moduleName)
    $script:publicPath = Join-Path -Path $script:projectRoot -ChildPath 'Public'
}

Describe 'Module Manifest' {
    BeforeAll {
        $script:projectRoot = Split-Path -Path $PSScriptRoot -Parent | Split-Path -Parent
        $script:moduleName = (Get-ChildItem -Path $script:projectRoot -Filter '*.psd1' | Select-Object -First 1).BaseName
        $script:manifestPath = Join-Path -Path $script:projectRoot -ChildPath ('{0}.psd1' -f $script:moduleName)
        $script:publicPath = Join-Path -Path $script:projectRoot -ChildPath 'Public'
        $script:manifest = Test-ModuleManifest -Path $script:manifestPath -ErrorAction Stop
        $script:manifestData = Import-PowerShellDataFile -Path $script:manifestPath
    }

    It 'passes Test-ModuleManifest' {
        $script:manifest | Should -Not -BeNullOrEmpty
    }

    It 'has a valid GUID' {
        { [System.Guid]::Parse($script:manifest.Guid) } | Should -Not -Throw
    }

    It 'declares an Author' {
        $script:manifest.Author | Should -Not -BeNullOrEmpty
    }

    It 'declares a Description' {
        $script:manifest.Description | Should -Not -BeNullOrEmpty
    }

    It 'declares ModuleVersion' {
        $script:manifest.Version | Should -BeOfType ([System.Version])
    }

    It 'sets PowerShellVersion to 5.1 or later' {
        $script:manifest.PowerShellVersion | Should -BeGreaterOrEqual ([System.Version] '5.1')
    }

    It 'sets RootModule to PS.DCU.psm1' {
        $script:manifest.RootModule | Should -Be 'PS.DCU.psm1'
    }

    It 'declares an explicit FunctionsToExport array' {
        $script:manifestData.FunctionsToExport | Should -Not -Contain '*'
        $script:manifestData.FunctionsToExport.Count | Should -BeGreaterThan 0
    }

    It 'has FunctionsToExport matching Public/*.ps1 filenames' {
        $publicFiles = Get-ChildItem -Path $script:publicPath -Filter '*.ps1' -File | Select-Object -ExpandProperty BaseName | Sort-Object
        $exported = $script:manifestData.FunctionsToExport | Sort-Object
        $exported | Should -Be $publicFiles
    }

    It 'declares empty CmdletsToExport, VariablesToExport, AliasesToExport' {
        $script:manifestData.CmdletsToExport | Should -BeNullOrEmpty
        $script:manifestData.VariablesToExport | Should -BeNullOrEmpty
        $script:manifestData.AliasesToExport | Should -BeNullOrEmpty
    }

    It 'includes ProjectUri in PSData' {
        $script:manifestData.PrivateData.PSData.ProjectUri | Should -Not -BeNullOrEmpty
    }
}
