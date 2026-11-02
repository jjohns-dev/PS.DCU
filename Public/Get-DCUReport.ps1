function Get-DCUReport {
    <#
    .SYNOPSIS
        Parse existing Dell Command Update XML reports into objects.
    .DESCRIPTION
        Reads one or more Dell Command Update XML report files from the supplied path
        (or from the default report directory at %ProgramData%\Dell\CommandUpdate\Reports)
        and returns one PSCustomObject per update entry.
    .PARAMETER Path
        Path to an XML report file or to a directory containing reports. When omitted,
        the default DCU report directory is used.
    .INPUTS
        System.String.
    .OUTPUTS
        System.Management.Automation.PSCustomObject.
    .EXAMPLE
        PS C:\> Get-DCUReport
        Parses every XML report in the default DCU reports directory.
    .EXAMPLE
        PS C:\> Get-DCUReport -Path 'C:\Reports\dcu\DCUApplicableUpdates.xml'
        Parses a specific DCU report file.
    .NOTES
        Name:     Get-DCUReport
        Author:   johnsarie27
        Version:  0.1.0 | Last Edit: 2026-05-20
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, HelpMessage = 'Path to a report file or directory')]
        [ValidateNotNullOrEmpty()]
        [System.String] $Path
    )
    Begin {
        Set-StrictMode -Version Latest
        Write-Verbose -Message ('Starting {0}' -f $MyInvocation.MyCommand)
    }
    Process {
        if (-not $PSBoundParameters.ContainsKey('Path')) {
            $Path = $dcu_report_path
        }

        if (-not (Test-Path -Path $Path)) {
            Write-Error -Message ('Report path not found: [{0}]' -f $Path) -ErrorAction Stop
        }

        ConvertFrom-DCUReport -Path $Path
    }
}
