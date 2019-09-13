param(
    
    [Parameter(Mandatory= $false)]
    [string]$SubscriptionId,
    
    [string]$ResourceGroup
)


function Get-AccessToken {
    $context = Get-AzContext
    if ($null -eq $account.Account) {
        Write-Output("Account Context not found, please login")
        Connect-AzAccount
        $context = Get-AzContext
    }
    Set-AzContext -SubscriptionId $SubscriptionId
    $cache = $context.TokenCache
    $cacheItemToUse = $cache.ReadItems()

    $tokenToUse = ($cacheItemToUse | where { $_.ExpiresOn -gt (Get-Date) })[0].accessToken

    return $tokenToUse
}

function Trigger-ResourceGroupPolicy {
    param (
        [string]$ResourceGroup,
        [string]$SubscriptionId,
        $Headers
    )

    $url = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.PolicyInsights/policyStates/latest/triggerEvaluation?api-version=2018-07-01-preview"
    
    $response= Invoke-WebRequest -Uri $url -Method Post -Headers $Headers

    return $response 
}

function Trigger-SubscriptionPolicy {
    param (
        [string]$SubscriptionId,
        $Headers
    )

    $context = Get-AzContext
    $cache = $context.TokenCache
    $cacheItemToUse = $cache.ReadItems()

    $tokenToUse = ($cacheItemToUse | where { $_.ExpiresOn -gt (Get-Date) })[0].accessToken

    $url = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.PolicyInsights/policyStates/latest/triggerEvaluation?api-version=2018-07-01-preview"

    $response= Invoke-WebRequest -Uri $url -Method Post -Headers $Headers
    return $response 
}

function Get-Status {
    [string]$StatusUrl,
        $Headers
    $res= Invoke-WebRequest -Uri $StatusUrl -Method Get -Headers $Headers
    return $res
}

$token = Get-AccessToken

$headers = @{
    Authorization = "Bearer $token"
}
if(($null -eq $ResourceGroup) -or ($ResourceGroup -eq '')){
    $res = Trigger-SubscriptionPolicy -SubscriptionId $SubscriptionId -Headers $headers
}
else{
    $res = Trigger-ResourceGroupPolicy -ResourceGroup $ResourceGroup -SubscriptionId $SubscriptionId -Headers $headers
}

$statusUrl = $res.Headers.Location
Write-Output "Token is: $($token)"

Write-Output "Status url is: $($res.Headers.Location)"

Get-Status -StatusUrl $statusUrl -Headers $headers

#Write-Output "Run this command: Get-Status -StatusUrl $statusUrl -Headers $headers"
#Invoke-WebRequest -Uri $statusUrl -Method Get -Headers $headers