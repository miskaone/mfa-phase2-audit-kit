@{
    # PSScriptAnalyzer settings for MFA Phase 2 Audit Kit
    # Custom rules and exclusions for PowerShell code quality
    
    # Include default rules
    IncludeDefaultRules = $true
    
    # Custom rule configurations
    Rules = @{
        # Allow longer lines for readability in audit scripts
        PSProvideCommentHelp = @{
            Enable = $true
            ExcludeRules = @('PSProvideCommentHelp')
        }
        
        # Allow Write-Host for user feedback in audit scripts
        PSAvoidUsingWriteHost = @{
            Enable = $false
        }
        
        # Allow positional parameters for common audit parameters
        PSAvoidUsingPositionalParameters = @{
            Enable = $false
        }
        
        # Allow empty catch blocks for error handling
        PSAvoidEmptyCatchBlock = @{
            Enable = $false
        }
        
        # Allow ShouldProcess for destructive operations (future use)
        PSShouldProcess = @{
            Enable = $true
        }
        
        # Enforce proper error handling
        PSAvoidUsingCmdletAliases = @{
            Enable = $true
        }
        
        # Enforce consistent parameter naming
        PSAvoidUsingPlainTextForPassword = @{
            Enable = $true
        }
        
        # Require proper variable naming
        PSUseApprovedVerbs = @{
            Enable = $true
        }
    }
    
    # Exclude specific paths from analysis
    ExcludeRules = @(
        'PSAvoidUsingPlainTextForPassword'  # Allow for example data
    )
    
    # Custom severity overrides
    Severity = @{
        Error = @('PSAvoidUsingPlainTextForPassword')
        Warning = @('PSProvideCommentHelp', 'PSAvoidUsingWriteHost')
        Information = @('PSUseApprovedVerbs')
    }
}
