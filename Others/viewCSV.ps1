param (
	$File
)

Function Get-File($initialDirectory="E:\shares\HPPT-RD-01") {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null

    $openFileDialog = New-Object System.Windows.Forms.openFileDialog 
    #$openFileDialog.InitialDirectory = $initialDirectory;
    $openFileDialog.Filter = "All files (*.*)|*.*|CSV files (*.csv)|*.csv";
    $openFileDialog.FilterIndex = 2;
    $openFileDialog.RestoreDirectory = $true;
	
    if($openFileDialog.ShowDialog() -eq "OK") {
        $filename = $openFileDialog.FileName
    }
    return $filename
}
if(-not($PSBoundParameters.ContainsKey('File')))
{
	$File=Get-File
}
Import-Csv -Path $File | ogv -Title "$File"