param (
	$filter=$env:COMPUTERNAME
)
Get-ADComputer -Filter "Name -like '$filter'" -properties * | select Name, OperatingSystem,OperatingSystemVersion,Ipv4Address | 
	where {
		(Test-Connection $_.name -Count 1 -ea SilentlyContinue)
	} | ForEach-Object {
		$CS = Get-WmiObject -ComputerName $_.Ipv4Address -ClassName Win32_ComputerSystem
		$BIOS = Get-WmiObject -ComputerName $_.Ipv4Address -ClassName Win32_BIOS
		$OS = Get-WmiObject -ComputerName $_.Ipv4Address -ClassName Win32_OperatingSystem
		$PROC = Get-WmiObject -ComputerName $_.Ipv4Address -ClassName Win32_Processor

		New-Object -TypeName psobject -Property @{
			'00-Date' = Get-Date
			'01-Name' = $CS.Name
			'02-Manufacturer' = $CS.Manufacturer
			'03-Model' = $CS.Model
			'04-Memory(Gb)' = $CS.TotalPhysicalMemory / 1GB -as [int]
			'05-CPU' = $PROC.name
			'06-OperatingSystem' = $_.OperatingSystem
			Name = $_.name
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
		}
	}
