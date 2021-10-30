param (
	[string]$filter='*'
)

Get-ADComputer -Filter "Name -like '$filter'" -properties * | select Name, OperatingSystem,OperatingSystemVersion,Ipv4Address | 
	where {
		(Test-Connection $_.Name -Count 1 -ea SilentlyContinue)
	} | ForEach-Object {
		$name = $_.Name
		Write-host "Get looged user on $name"
		try {
			$user = quser /server:$name
			if ($?) {
				$user | ForEach-Object -Process { $_ -replace '\s{2,}',',' }| ConvertFrom-CSV| Where-Object -FilterScript {$_.SESSIONNAME -eq 'console'} | ForEach {
					$_ | Add-Member -MemberType NoteProperty -Name "Computer" -Value $name
					$_
				}
			} else {
				throw $error[0]
			}
		} catch {
			Write-Warning "Not possible to get logged users from ${name}: $_"
		} 
	}
	