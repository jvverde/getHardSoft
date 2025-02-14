param (
	$filter=$env:COMPUTERNAME
)
Get-ADComputer -Filter "Name -like '$filter'" -properties * | select Name, OperatingSystem,OperatingSystemVersion,Ipv4Address | 
	where {
		(Test-Connection $_.name -Count 1 -ea SilentlyContinue)
	} | ForEach-Object {
		$name = $_.name
		try {
			$SessionArgs = @{
				 ComputerName  = $_.name
				 SessionOption = New-CimSessionOption -Protocol Dcom
			}
			$MethodArgs = @{
				ClassName     = 'Win32_Process'
				MethodName    = 'Create'
				CimSession    = New-CimSession @SessionArgs -ErrorAction Stop
				Arguments     = @{
					CommandLine = "powershell Start-Process powershell -ArgumentList 'Enable-PSRemoting -Force'"
				}
			}
			Write-Host "Enable-PSRemoting on", $name
			Invoke-CimMethod @MethodArgs
			Write-Host "Done"
		} catch {
			Write-Warning "$_ ($name)"
		}
	}
