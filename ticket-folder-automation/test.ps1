# vars
$process = Get-Process | Where-Object { $_.CPU -gt 100 } | Sort-Object CPU -Descending