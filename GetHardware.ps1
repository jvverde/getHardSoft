param (
	[Parameter(Mandatory)]$output,
	$filter=$env:COMPUTERNAME
)

$TempFile = [System.IO.Path]::GetTempFileName()
$result = "${output}.csv"
$errors = "${output}.err"

if (Test-Path -Path $result -PathType Leaf) {
	Copy-Item $result -Destination $TempFile
}

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
				'01-Name' = $CS.Name
				'02-Manufacturer' = $CS.Manufacturer
				'03-Model' = $CS.Model
				'04-Memory(Mb)' = $CS.TotalPhysicalMemory / 1MB -as [int]
				'05-CPU' = $PROC.name
				'06-OperatingSystem' = $_.OperatingSystem
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
			New-Object -TypeName psobject -Property @{
				Computer = $name
				date = Get-Date
				error = $_
			} | Export-CSV "$errors" -Append
		}
	}
	
# Remove duplicate lines from csv file
$myhash = @{}
Import-CSV -Path $TempFile| %{$myhash[$_."01-Name" + $_.ADName] = $_ }
$myhash.values | Export-CSV $result

Remove-Item $TempFile
Write-host "The results are in '$result' and errors in '$errors'"
