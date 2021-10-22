Param(
     [Parameter(Mandatory=$True, Position=0)]
     $pairs = $(throw "Please enter name and filter as a pair. Ex: boa, pt-cboa-*")
 )

for(;;) {
	foreach ($p in $pairs) {
		$name, $filter = $p.split('=')
		& "${PSScriptRoot}\GetHardware.ps1" "$name" "$filter"
	}
	Start-Sleep 300
}