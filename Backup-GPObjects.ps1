# Configuration (change this to match to your configuration)
$domain = "contoso.com"
$server = "dc.contoso.com"
$backupFolder = "D:\GPOBackup\"
$errorFolder = "D:\logs\ErrorLog\"
$errorLog = $errorFolder + "Backup-GPObjects.txt"

# Variables
$GPOs = $null

# Send mail function
function m_SendMail ([string]$msgText)
{
    $smtpServer = "mail.contoso,com"
    $from = "alert@contoso.com"
    $to = "my.name@contoso.com"
    $subject = "[ALERT] $server - GPO Backup"

    Send-MailMessage -SmtpServer $smtpServer -From $from -To $to -Subject $subject -Body $msgText

}# end function

# Create ErrorLog folder
function m_CreateFolder([string]$folder)
{
    try
    {
        mkdir -Path $folder
    }
    catch
    {
        m_SendMail($Error.Item($Error.Count - 1) | Format-List * -Force)
    }
}# end function

# Check and create folders
if ((Test-Path -Path $errorFolder) -eq $false) { m_CreateFolder($errorFolder) }
if ((Test-Path -Path $backupFolder) -eq $false) { m_CreateFolder($backupFolder) }

# Delete backups older than 90 days (change -90 to -number of days you are required to keep your GPO backups)
try
{
    Get-ChildItem $backupFolder |? {$_.PSIsContainer -and $_.LastWriteTime -le (Get-Date).AddDays(-90)} |% {Remove-Item $backupFolder$_ -Recurse -Force }
}
catch
{
    m_SendMail($Error.Item($Error.Count - 1) | Format-List * -Force)
}

# Create new date/time formated folder for backup
$backupFolderDate = Get-Date -Format o | foreach {$_ -replace ":", "."}

$backupFolder = $backupFolder + $backupFolderDate
if ((Test-Path -Path $backupFolder) -eq $false) { m_CreateFolder($backupFolder) }

# Backup GPO's
try
{
    $GPOs = Get-GPO -All -Server $server -Domain $domain
}
catch
{
        Get-Date >> $errorLog
        $Error.Item($Error.Count - 1) | Format-List * -Force >> $errorLog 
        "----------------------------------------------------------------" | Out-File -FilePath $errorLog -Append
        m_SendMail($Error.Item($Error.Count - 1) | Format-List * -Force)
}#end try

foreach ($GPO in $GPOs)
{
    try
    {
        Backup-GPO -Guid $GPO.Id -Path $backupFolder -Server $server -Domain $domain -Verbose
    }
    catch
    {
        Get-Date >> $errorLog
        $Error.Item($Error.Count - 1) | Format-List * -Force >> $errorLog 
        "----------------------------------------------------------------" | Out-File -FilePath $errorLog -Append
        m_SendMail($Error.Item($Error.Count - 1) | Format-List * -Force) 
    }#end try
}#end foreach