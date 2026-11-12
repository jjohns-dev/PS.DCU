# ==============================================================================
# Filename: help.tests.ps1
# Version:  0.1.2 | Updated: 2026-11-02
# Author:   johnsarie27
# ==============================================================================

BeforeDiscovery {
    $projectRoot = Split-Path -Path $PSScriptRoot -Parent | Split-Path -Parent
    $moduleName = (Get-ChildItem -Path $projectRoot -Filter '*.psd1' | Select-Object -First 1).BaseName
    $manifestPath = Join-Path -Path $projectRoot -ChildPath ('{0}.psd1' -f $moduleName)

    if (Get-Module -Name $moduleName) {
        Remove-Module -Name $moduleName -Force
    }
    Import-Module -Name $manifestPath -Force -ErrorAction Stop

    # Names only, not CommandInfo objects: CommandInfo in -ForEach hangs Pester 6.0.0 (fixed by 6.2.0).
    $script:helpTestCases = (Get-Command -Module $moduleName -CommandType Function) | ForEach-Object -Process {
        @{ Name = $_.Name }
    }
}

Describe 'Comment-based help on <Name>' -ForEach $script:helpTestCases {
    BeforeAll {
        $script:help = Get-Help -Name $Name -Full
    }

    It 'has a synopsis' {
        $script:help.Synopsis | Should -Not -BeNullOrEmpty
        $script:help.Synopsis | Should -Not -Match '^\s*$'
    }

    It 'has a description' {
        ($script:help.Description | Out-String).Trim() | Should -Not -BeNullOrEmpty
    }

    It 'has at least one example' {
        @($script:help.Examples.Example).Count | Should -BeGreaterThan 0
    }

    It 'documents every parameter' {
        $command = Get-Command -Name $Name
        # AST, not Get-Help, for both checks: Get-Help synthesizes an entry for a parameter with no .PARAMETER
        # and drops a .PARAMETER naming no real parameter, so neither check could fail against it.
        $helpContent = if ($command.ScriptBlock) { $command.ScriptBlock.Ast.GetHelpContent() }
        $documented = @(if ($helpContent) { $helpContent.Parameters.Keys | Where-Object -FilterScript { $_ } })
        $declared = $command.Parameters.Keys | Where-Object -FilterScript {
            $_ -notin @('Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable', 'WhatIf', 'Confirm', 'ProgressAction')
        }

        foreach ($p in $declared) {
            $documented | Should -Contain $p -Because ('Parameter [{0}] on [{1}] must have a .PARAMETER help entry' -f $p, $Name)
        }

        foreach ($p in $documented) {
            $command.Parameters.Keys | Should -Contain $p -Because ('.PARAMETER [{0}] on [{1}] names a parameter the command does not declare' -f $p, $Name)
        }
    }
}
