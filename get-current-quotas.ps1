param(
    [Parameter()]
    [Switch] $v  #verbose
)

$resultspath = "$PSScriptRoot\results"
$date = Get-Date -Format "yy/MM/dd"

if (-not(Test-Path $PSScriptRoot\last-run -PathType Leaf)) { New-Item $PSScriptRoot\last-run -Type File }
if (-not((Get-Content $PSScriptRoot\last-run) -eq $date)) {

    if ($v) { Write-Output "checking Azure credentials" }
    $account = Get-AzContext
    if (!$account) { Connect-AzAccount | Out-Null }

    if ($v) { Write-Output "checking file structure" }
    if (-not(test-path $resultspath)) { mkdir $resultspath | out-null }

    Get-AzResourceGroup -tag @{"uts_project"="virtual_labs"} | ForEach-Object {
        $rgpath = "$resultspath\$($_.ResourceGroupName)"
        if (-not($_.ResourceGroupName -eq 'uts-npd-testlab-rg')) {
            if (-not(test-path $rgpath)) { mkdir $rgpath | out-null }
            
            if ($v) { Write-Output "getting users for labs in $($_.ResourceGroupName):" }
            Get-AzLabServicesLab -ResourceGroupName $_.ResourceGroupName | ForEach-Object {

                if ($v) { Write-Output " - $($_.Name)" }
                $labfile = "$rgpath\$($_.Name).csv"
                if (-not(test-path $labfile)) { "Date,Email,Usage,Quota" > $labfile }

                Get-AzLabServicesUser -Lab $_ | ForEach-Object {
                    "$date,$($_.Email),$($_.TotalUsage),$($_.AdditionalUsageQuota)" >> $labfile
                }
            }
        }
    }
    $date > $PSScriptRoot\last-run
}
else {
    if ($v) { Write-Output "Already run today" }
}