@{
    PSDependOptions  = @{
        Target     = 'CurrentUser'
        Parameters = @{
            Repository         = 'PSGallery'
            SkipPublisherCheck = $true
        }
    }

    Pester           = '6.2.0'
    psake            = '5.0.4'
    PSScriptAnalyzer = '1.24.0'
}
