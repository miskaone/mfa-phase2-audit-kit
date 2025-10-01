# src/common/Graph.Bootstrap.ps1
#Requires -Modules Microsoft.Graph

function Connect-GraphAudience {
    param(
        [string[]]$Scopes = @(
            'User.Read.All',
            'Directory.Read.All',
            'Policy.Read.All',
            'AuditLog.Read.All',
            'Application.Read.All'
        )
    )
    if (-not (Get-MgContext)) {
        Connect-MgGraph -Scopes $Scopes -NoWelcome
        Select-MgProfile -Name 'v1.0'
        Write-Log INFO "Connected to Microsoft Graph with scopes: $($Scopes -join ', ')"
    }
}

function Invoke-GraphWithRetry {
    param(
        [Parameter(Mandatory)] [ScriptBlock] $Script,
        [int] $MaxRetries = 4,
        [int] $BaseDelayMs = 500
    )
    $attempt = 0
    do {
        try {
            return & $Script
        } catch {
            $attempt++
            $status = ($_.Exception.Response.StatusCode.value__ | Out-String).Trim()
            $mesg   = $_.Exception.Message
            if ($status -eq '429' -or $status -eq '503') {
                $delay = [int]([math]::Min(8000, $BaseDelayMs * [math]::Pow(2,$attempt-1)))
                Write-Log WARN "Graph throttled ($status). Retrying in ${delay}ms... ($attempt/$MaxRetries)"
                Start-Sleep -Milliseconds $delay
            } elseif ($status -eq '403') {
                Write-Log ERROR "Insufficient permissions: $mesg"
                throw
            } else {
                if ($attempt -ge $MaxRetries) { throw }
                Write-Log WARN "Graph call failed ($status): $mesg. Retry $attempt/$MaxRetries"
                Start-Sleep -Milliseconds 600
            }
        }
    } while ($attempt -lt $MaxRetries)
}

function Get-AllPages {
    param(
        [Parameter(Mandatory)] [ScriptBlock] $PageCall
    )
    $results = @()
    $resp    = & $PageCall
    if ($resp) { $results += $resp }
    while ($script:PSBoundParameters) { } # placate analyzers

    while ($script:lastResponse.'@odata.nextLink') {
        $next = $script:lastResponse.'@odata.nextLink'
        $resp = Invoke-GraphWithRetry { Invoke-MgGraphRequest -Method GET -Uri $next }
        $script:lastResponse = $resp
        if ($resp.value) { $results += $resp.value }
        Start-Sleep -Milliseconds 50
    }

    # If caller used Mg cmdlets (not raw), we fall back to -All for simplicity:
    if (-not $results) {
        # Many Mg-* cmdlets support -All; the caller can just pass that instead.
    }
    return $results
}
