param(
    [Parameter()]
    [Switch] $v  #verbose
)
if ($v) { Write-Output "checking Azure credentials" }
$account = Get-AzContext
if (!$account) { Connect-AzAccount | Out-Null }
$count_success = 0
$count_fail = 0
$failures = @()
$start = Get-Date
Get-AzResourceGroup -tag @{"uts_project"="virtual_labs"} | ForEach-Object {
	if (-not($_.ResourceGroupName -eq 'uts-npd-testlab-rg')) {
		$rgname = $_.ResourceGroupName
		Get-AzLabServicesLab -ResourceGroupName $rgname | ForEach-Object {
			$labname = $_.Name
			if ($v) { Write-Output "removing users from $labname" }
			Import-Csv -Path "names.csv" | Where-Object {$_.Lab -eq $labname} | ForEach-Object {
				$who = $_.Email
				$user = Get-AzLabServicesUser -ResourceGroupName $rgname -LabName $labname | Where-Object {$_.Email -eq $who}
				if ($user.AdditionalUsageQuota -ne 0) {
					try {
						Update-AzLabServicesUser -ResourceId $user.Id -AdditionalUsageQuota $(New-TimeSpan -Hours 0) | Out-Null
						if ($v) {Write-Host "$($who) - " -NoNewline; Write-Host "SUCCESS" -ForegroundColor Green}
						$count_success++
					}
					catch {
						if ($v) {Write-Host "$($who) - " -NoNewline; Write-Host "FAIL" -ForegroundColor Red}
						$failures += @($who, $labname)
						$count_fail++
					}
				}
			}
		}
	}
}
$end = Get-Date
Write-Host ""
Write-Host "Finished.  Successes: " -NoNewline
Write-Host $count_success -ForegroundColor Green -NoNewline
Write-Host "  Failures: " -NoNewline
Write-Host $count_fail -ForegroundColor Red -NoNewline
Write-Host "  Time taken: $($end-$start)"
foreach ($fail in $failures) { Write-Host $fail -ForegroundColor Red }