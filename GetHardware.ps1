param (
	[Parameter(Mandatory)]$output,
	$filter=$env:COMPUTERNAME
)

$TempFile = [System.IO.Path]::GetTempFileName()
$result = "${output}.csv"
$errors = "${output}.err"

Get-ADComputer -Filter "Name -like '$filter'" -properties * | select Name, OperatingSystem,OperatingSystemVersion,Ipv4Address | 
	where {
		(Test-Connection $_.Name -Count 1 -ea SilentlyContinue)
	} | ForEach-Object {
		$name = $_.Name
		Write-host "Get info from $name"
		try {
			$CS = Get-WmiObject -ComputerName $_.Name -ClassName Win32_ComputerSystem -ErrorAction stop
			$BIOS = Get-WmiObject -ComputerName $_.Name -ClassName Win32_BIOS -ErrorAction stop
			$OS = Get-WmiObject -ComputerName $_.Name -ClassName Win32_OperatingSystem -ErrorAction stop
			$PROC = Get-WmiObject -ComputerName $_.Name -ClassName Win32_Processor -ErrorAction stop

			New-Object -TypeName psobject -Property @{
				ADName = $name
				'00-Date' = Get-Date
				'00-Origin' = $env:computername
				'01-Name' = $CS.Name
				'02-Manufacturer' = $CS.Manufacturer
				'03-Model' = $CS.Model
				'04-Memory(Mb)' = $CS.TotalPhysicalMemory / 1MB -as [int]
				'05-CPU' = $PROC.name
				'06-OperatingSystem' = $_.OperatingSystem
				'07-LastUser' = $CS.UserName
				'CPU Caption' = $PROC.Caption
				'CPU Manufacturer' = $PROC.Manufacturer
				'CPU Speed (Mhz)' = $PROC.MaxClockSpeed
				'BIOS SMBIOSBIOSVersion' = $BIOS.SMBIOSBIOSVersion
				'BIOS Name' = $BIOS.Name
				'BIOS Version' = $BIOS.Version
				'BIOS Manufacturer' = $BIOS.Manufacturer
				'BIOS SeriaNumber' = $BIOS.SerialNumber
				'OS BuildNumber' = $OS.BuildNumber
				'OS SerialNumber' = $OS.SerialNumber
				'OS Version' = $OS.Version
			} | %{
				$obj = New-Object psobject
				$_.psobject.properties | Sort Name | %{Add-Member -Inp $obj NoteProperty $_.Name $_.Value}
				$obj
			} | Export-CSV $TempFile -Append
		} catch {
			Write-host "Not possible to get values from ${name}: $_"
			try {
				$ip = (Resolve-DnsName -Name $name).IPAddress
				$resolve = (Resolve-DnsName -Name $ip).NameHost
				New-Object -TypeName psobject -Property @{
					'01-Computer' = $name
					'00-Date' = Get-Date
					error = $_
					'00-Origin' = $env:computername
					'02-Ip' = $ip
					'03-Resolve' = $resolve
				} | %{
					$obj = New-Object psobject
					$_.psobject.properties | Sort Name | %{Add-Member -Inp $obj NoteProperty $_.Name $_.Value}
					$obj
				} | Export-CSV "$errors" -Append
			} catch {
				Write-Warning "$_"
			}
		} 
	}
	
# Remove duplicate lines from csv file
$myhash = @{}

if (Test-Path -Path "$result" -PathType Leaf) {
	#First import previous results if any
	Import-CSV -Path $result| %{
		if ($_."01-Name" -ne $null) {
			$myhash[$_."01-Name"] = $_
		}
	}
}

Import-CSV -Path $TempFile| %{
	if ($_."01-Name" -ne $null) {
		$myhash[$_."01-Name"] = $_
	}
}

$myhash.values | Sort  -Descending '00-Date'| Export-CSV "$result"

Remove-Item $TempFile
Write-host "The results are in '$(Get-Item "$result")' and errors in '$(Get-Item "$errors")'"
