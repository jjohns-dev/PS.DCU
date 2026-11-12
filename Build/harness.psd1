@{
    # OPTIONAL. Copy this file to Build/harness.psd1 only if your module needs one of the
    # settings below. A module that needs none of them should not have the file at all.
    # Any key not listed here stops the build, so a misspelt setting cannot be silently ignored.

    # PSScriptAnalyzer rules to exclude for this module only. String array; default none.
    # Used by AWSAutomation: AWS.Tools.* authenticates with AWSCredentials, never PSCredential.
    # PSScriptAnalyzerExcludeRules = @('PSUsePSCredentialType', 'PSAvoidUsingPlainTextForPassword')

    # Pester tags to exclude from the gating build. String array; default none.
    # Used by PS.SSL: tests tagged Network call a live third-party endpoint.
    # PesterExcludeTag = @('Network')

    # Run this module's tests under Set-StrictMode -Version Latest. Boolean; default $false.
    # Used by PS.DCU. Confirm your tests pass under strict mode before turning it on.
    PesterStrictMode = $true
}
