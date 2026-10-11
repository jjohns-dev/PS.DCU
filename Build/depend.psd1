@{
    PSDependOptions  = @{
        Target     = 'CurrentUser'
        Parameters = @{
            Repository         = 'PSGallery'
            SkipPublisherCheck = $true
        }
    }

    Pester           = '6.2.0'
    psake            = '4.9.1'
    PSScriptAnalyzer = '1.24.0'
}
