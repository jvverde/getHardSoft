Get-ChildItem -Path $env:USERPROFILE/AppData/ -Recurse -Exclude exception.sites | 
	Where { ! $_.PSIsContainer } | 
	Where-Object { $_.FullName -match 'sun\\java' } |
	sort length -Descending | 
	Select -ExpandProperty FullName |
	Remove-Item