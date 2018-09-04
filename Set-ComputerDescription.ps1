# Settings
$computersOU = "OU=Workstations,DC=sberbank,DC=hr"
$domainServer = "domain.local"
$logSource = "My-PowerShell"

# Variables
$computerUser = $null
$computerName = $null
$computerAlive = $false
$computerUser = $null
$computerUserArray = $null
$computerUserName = $null
$user = $null
$userInfo = $null
$newLine = [Environment]::NewLine
$scriptName = $MyInvocation.MyCommand.Name
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Create Event Log Source
try
{
    New-EventLog -LogName Application -Source $logSource -ErrorAction Stop
}
catch
{
    if(($Error[0].Message.Contains("Access is denied")) -eq $true)
    {
        Write-Host "Cannot create Event Log source with name $logSource. Please create Event Log Source with name $logSource as Administrator, otherwise no Event logging will be performed."
    }
}

Write-EventLog -LogName Application -Source $logSource -EntryType Information -EventId 26061 -Message "$scriptName${NewLine}cmdlet starting"

# Get list of computers
try
{
    $computers = Get-ADComputer -Filter * -SearchBase $computersOU -SearchScope Subtree -Server $domainServer -ErrorAction Stop
    Write-EventLog -LogName Application -Source $logSource -EntryType Information -EventId 26062 -Message "$scriptName${NewLine}Successfuly loaded a list of computers"
}
catch
{
    Write-EventLog -LogName Application -Source $logSource -EntryType Error -EventId 26064 -Message "$scriptName${NewLine}Failed to get a list of computers"
}#end try

# Loop through all computers
foreach($computer in $computers)
{
    $computerName = $computer.Name

    # Check if computer is turned on
    $computerAlive = Test-Connection -ComputerName $computerName -BufferSize 16 -Count 1 -Quiet

    if($computerAlive -eq $true)
    {
        # Get loggedon user
        try
        {
            $computerUser = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $computerName -ErrorAction Stop | Select-Object UserName
            Write-EventLog -LogName Application -Source $logSource -EntryType Information -EventId 26062 -Message "$scriptName${NewLine}Successfuly got $computerUser from $computerName"
        }
        catch
        {
            $computerUser = $null
            Write-EventLog -LogName Application -Source $logSource -EntryType Error -EventId 26064 -Message "$scriptName${NewLine}Failed to get Win32_ComputerSystem WMI from $computerName"
        }#end try

        if($computerUser.UserName -ne $null)
        {
            $computerUserArray = $computerUser.UserName.Split("\")

            $computerUserName = $computerUserArray[1]
            
            # Get user from AD
            try
            {
                $user = Get-ADUser -Filter {SamAccountName -eq $computerUserName} -Properties Initials, physicalDeliveryOfficeName -Server $domainServer
                if($user -eq $null)
                {
                    $userInfo = $null
                    Write-EventLog -LogName Application -Source $logSource -EntryType Warning -EventId 26063 -Message "$scriptName${NewLine}$computerUserName not found in Active Directory"
                }
                else
                {    
                    $userInfo = $user.Name + ", " + $user.physicalDeliveryOfficeName
                    Write-EventLog -LogName Application -Source $logSource -EntryType Information -EventId 26062 -Message "$scriptName${NewLine}Successfuly loaded user information: $userInfo"
                }#end if
            }
            catch
            {
                $userInfo = $null
            }#end try
            
            # Set user information to Computer account description
            if($userInfo -ne $null)
            {
                try
                {
                    Set-ADComputer -Identity $computerName -Description $userInfo -Server $domainServer -ErrorAction Stop
                    Write-EventLog -LogName Application -Source $logSource -EntryType Information -EventId 26062 -Message "$scriptName${NewLine}Successfuly set $userInfo to computer $computerName"
                }
                catch
                {
                    Write-EventLog -LogName Application -Source $logSource -EntryType Error -EventId 26064 -Message "$scriptName${NewLine}Failed to set user info to computer $computerName"
                }#end try
            }#end if
        }#end if
    }#end if

    # Clear variables
    $computerUser = $null
    $computerName = $null
    $computerAlive = $false
    $computerUser = $null
    $computerUserArray = $null
    $computerUserName = $null
    $user = $null
    $userInfo = $null
}#end foreach

Write-EventLog -LogName Application -Source $logSource -EntryType Information -EventId 26061 -Message "$scriptName${NewLine}cmdlet finished"