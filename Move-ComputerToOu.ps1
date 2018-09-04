# Settings
$newLine = [Environment]::NewLine
$scriptName = $MyInvocation.MyCommand.Name
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
[int]$counter = 1
[int]$counterMax = 1
[int]$percent = 1

# Log settings
$logPath = "D:\Scripts\PowerShell\Logs"
$logDate = Get-Date -Format yyyy-MM-dd-HH-mm
$logName = "$scriptName-$logDate.log"
$logSource = "SBHR-PowerShell"

# Variables
$computers = $null
$computer = $null
$computerName = $null
$computerType = $null
$ouDesktops = "OU=Desktops,OU=Workstations,DC=sberbank,DC=hr"
$ouThins = "OU=Thins,OU=Workstations,DC=sberbank,DC=hr"
$ouLaptops = "OU=Laptops,OU=Workstations,DC=sberbank,DC=hr"

# Save data to log file
function Save-Log([string]$inputText, [switch]$fileLog, [switch]$eventLog)
{
    $logMessage = "$(Get-Date -Format "dd.MM.yyyy HH:mm") - $inputText"

    if($fileLog)
    {
        # Create folder if missing
        if((Test-Path $logPath) -eq $false)
        {
            try
            {
                New-Item -Path $logPath -ItemType Directory -ErrorAction Stop
            }
            catch
            {
                Write-Host "[ERROR] - Failed to create log folder - $logPath" -ForegroundColor Red 
            }#end try
        }#end if

        $logMessage | Out-File "$logPath\$logName" -Append
    }#end if

    if($eventLog)
    {
        # Create Event Log Source
        try
        {
            New-EventLog -LogName Application -Source $logSource -ErrorAction Stop
        }
        catch
        {
            #Write-Host "Error creating Event Log Source - $($Error[0])" -ForegroundColor Red
        }#end try

        $inputText = "$scriptName${NewLine}$inputText"

        if($inputText.ToLower().Contains("info")) # Info
        {
            Write-EventLog -LogName Application -Source $logSource -EntryType Information -EventId 26062 -Message $inputText
        }
        elseif($inputText.ToLower().Contains("warning")) # Warning
        {
            Write-EventLog -LogName Application -Source $logSource -EntryType Warning -EventId 26063 -Message $inputText
        }
        elseif($inputText.ToLower().Contains("error")) # Error
        {
            Write-EventLog -LogName Application -Source $logSource -EntryType Error -EventId 26064 -Message $inputText
        }
        elseif($inputText.ToLower().Contains("start")) # Script start
        {
            Write-EventLog -LogName Application -Source $logSource -EntryType Information -EventId 26061 -Message $inputText
        }
        elseif($inputText.ToLower().Contains("end")) # Script ended
        {
            Write-EventLog -LogName Application -Source $logSource -EntryType Information -EventId 26065 -Message $inputText
        }
        else
        {
            Write-EventLog -LogName Application -Source $logSource -EntryType Information -EventId 26062 -Message $inputText
        }#end if
    }
}#end function

# Write text to console
function Write-ToConsole ([string]$inputText)
{
    if($inputText.ToLower().Contains("info")) # Info
    {
        Write-Host $inputText -ForegroundColor Green
    }
    elseif($inputText.ToLower().Contains("warning")) # Warning
    {
        Write-Host $inputText -ForegroundColor Yellow
    }
    elseif($inputText.ToLower().Contains("error")) # Error
    {
        Write-Host $inputText -ForegroundColor Red
    }
    else 
    {
        Write-Host $inputText -ForegroundColor Gray
    }#end if
}#end function

Save-Log -inputText "[START] - $scriptName starting" -eventLog

try
{
    $computers = $null
    $computers = Get-ADComputer -Filter * -SearchBase "CN=Computers,DC=sberbank,DC=hr" -ErrorAction Stop
}
catch
{
    $computers = $null
}#end try

if ($computers -ne $null)
{
    foreach($computer in $computers)
    {
        $computerName = $computer.Name

        # Get computer type (last letter, D for desktop, P for portable - laptop) 
        $computerType = $computerName.Substring(($computerName.Length - 1), 1)

        # Add computer to printer deployment group (desktops and laptops)
        if(($computerType -eq "D") -or ($computerType -eq "P"))
        {
            $kod = $computerName.Substring(0, 4)

            $groupName = "HR_GRP_Printers_"
            $groupName += $kod
            $groupName += "xxxL"

            try
            {
                Add-ADGroupMember -Identity $groupName -Members $computer -ErrorAction Stop
                Save-Log -inputText "[INFO] Added $computerName to $groupName group for printer deployment" -eventLog
            }
            catch
            {
                Save-Log -inputText "[WARNING] - Failed to add $computerName to $groupName group for printer deployment" -eventLog
            }#end try
        }#end if

        # Move computer to propper OU
        if($computerType -eq "D")
        {
            try
            {
                Move-ADObject -Identity $computer -TargetPath $ouDesktops -ErrorAction Stop
                Save-Log -inputText "[INFO] - Moved $computerName to $ouDesktops" -eventLog
            }
            catch
            {
                Save-Log -inputText "[WARNING] - Failed to move $computerName to $ouDesktops" -eventLog
            }#end try
        }
        elseif($computerType -eq "P")
        {
            try
            {
                Move-ADObject -Identity $computer -TargetPath $ouLaptops -ErrorAction Stop
                Save-Log -inputText "[INFO] - Moved $computerName to $ouLaptops" -eventLog
            }
            catch
            {
                Save-Log -inputText "[WARNING] - Failed to move $computerName to $ouLaptops" -eventLog
            }#end try
        }
        elseif($computerType -eq "T")
        {
            try
            {
                Move-ADObject -Identity $computer -TargetPath $ouThins -ErrorAction Stop
                Save-Log -inputText "[INFO] - Moved $computerName to $ouThins" -eventLog
            }
            catch
            {
                Save-Log -inputText "[WARNING] - Failed to move $computerName to $ouThins" -eventLog
            }
        }
        else
        {
            Save-Log -inputText "[WARNING] - Cannot move $computerName to propper OU" -eventLog
        }#end if
    }#end foreach
}#end if
Save-Log -inputText "[END] - $scriptName ended sucessfully" -eventLog