@{
    RootModule           = 'PS.DCU.psm1'
    ModuleVersion        = '0.1.0'
    GUID                 = 'ae1aef27-57be-4124-8756-0db1affe094c'
    Author               = 'johnsarie27'
    CompanyName          = 'Unknown'
    Copyright            = '(c) johnsarie27. All rights reserved.'
    Description          = 'PowerShell module that wraps the Dell Command Update CLI (dcu-cli.exe).'
    PowerShellVersion    = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')

    FunctionsToExport    = @(
        'Get-DCUConfiguration'
        'Get-DCUDriverHistory'
        'Get-DCUReport'
        'Get-DCUUpdate'
        'Get-DCUVersion'
        'Install-DCUUpdate'
        'Invoke-DCUScan'
        'Set-DCUConfiguration'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()

    PrivateData          = @{
        PSData = @{
            Tags       = @('Dell', 'DCU', 'CommandUpdate', 'Drivers', 'BIOS', 'Firmware', 'Windows')
            LicenseUri = 'https://github.com/jjohns-dev/PS.DCU/blob/main/LICENSE'
            ProjectUri = 'https://github.com/jjohns-dev/PS.DCU'
        }
    }
}
