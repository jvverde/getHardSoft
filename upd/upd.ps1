#Requires -RunAsAdministrator

#The code bellow was adapted from https://www.reddit.com/r/PowerShell/comments/hbhc8i/sidder_but_better/

Function Get-Folder($initialDirectory="E:\shares\HPPT-RD-01") {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.Description = "Select a folder where UPDs reside"
    $foldername.rootfolder = "MyComputer"
    $foldername.SelectedPath = $initialDirectory

    if($foldername.ShowDialog() -eq "OK") {
        $folder += $foldername.SelectedPath
    }
    return $folder
}

$UPDLocation = Get-Folder

## Define the array which will be used to create the hash table
$vhdarray = @()

## Get list of all VHDs and all Open VHDs for comparison
$vhds = gci $UPDLocation | Where-Object {($_.Name -like "*.vhdx") -and ($_.name -notlike "*template*")}

$openfiles = get-smbopenfile | where {$_.path -Like "*.vhdx"}

## Check list of VHDs against open VHDs to determine if the disk is connected to on of the hosts
foreach($vhd in $vhds) {
    $openfiletest = ($openfiles | Where {$_.path -eq $vhd.FullName}) | select -Unique
    if ($openfiletest) {
        $vhdopened = $true
        $vhdrdshostip = $openfiletest.clientcomputername | select -Unique
        $vhdrdshost = ([System.Net.Dns]::gethostentry($vhdrdshostip)).hostname
    } else {
        $vhdopened = $false
        $vhdrdshost = "Not Connected"
    }

## Get user SID from VHD file name - then convert SID to username
    $usersid = ([io.path]::GetFileNameWithoutExtension($vhd.Name)).trim("UVHD-")
    $objSID = $Null
    try {
        $objSID = (New-Object System.Security.Principal.SecurityIdentifier ($usersid) -ErrorAction SilentlyContinue)
        $objSID = $objSID.Translate([System.Security.Principal.NTAccount])
    } catch {
        Write-Host "SID Not Translated - $usersid"
    }    

## Order the data into a hash table and add to the array
    $hash = [ordered]@{
        'Username' = $objSID.Value
        'VHD Connected' = $vhdopened
        'RDS Host' = $vhdrdshost
        'VHD Path' = $vhd.FullName
        'VHD Last Write' = $vhd.LastWriteTime
        'VHD Size (MB)' = $vhd.Length/1MB
    }
    
    $vhdproperties = New-Object -TypeName PSObject -Property $hash
    $vhdarray += $vhdproperties
}

$timestamp = get-date -f yyyy-MM-ddTHH-mm-ss
$vhdarray | sort Username | Export-Csv Reports\$timestamp.csv
write-host -ForegroundColor DarkCyan "Report Saved at Reports\$timestamp.csv"
$vhdarray | sort username | ogv -Title "VHD List"