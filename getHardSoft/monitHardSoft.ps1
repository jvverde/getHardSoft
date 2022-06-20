Param(
     [Parameter(Mandatory=$True, Position=0)]
     $pairs = $(throw "Please enter name and filter as a pair. Ex: boa, pt-cboa-*"),
     
	 [Parameter(Mandatory=$False, Position=1)]
	 $location=(Get-Location),
	 
     [Parameter(Mandatory=$False, Position=2)]
	 [int]$sleep=300
 )

$oldlocation = Get-Location

try{
	if (!(Test-Path -Path $location)) {
		New-Item -Path $location -ItemType "directory" -ea Stop
		$acl = Get-Acl "$location"
		$account = New-Object System.Security.Principal.Ntaccount("$env:UserDomain\$env:UserName")
		$acl.SetOwner($account)
		$acl| Set-Acl "$location"
	}

	Set-Location "$location"

	for(;;) {
		foreach ($p in $pairs) {
			$name, $filter = $p.split('=')
			try {
				& "${PSScriptRoot}\GetHardware.ps1" "$name" "$filter"
			}
			catch {
				Write-Warning "Error running GetHardware.ps1 $_"		
			}
		}
		Start-Sleep $sleep
	}
} catch {
	Write-Host $_
} finally {
	Set-Location "$oldlocation"
}