# List of all KB's for EternalBlue exploit, list updated on 17.05.2017
$hotfixes = @(‘KB4012598’, ‘KB4012212’, ‘KB4012215’, ‘KB4015549’, ‘KB4019264’, ‘KB4012213’, ‘KB4012216’, ‘KB4015550’, ‘KB4019215’, ‘KB4012214’, ‘KB4012217’, ‘KB4015551’, ‘KB4019216’, ‘KB4012606’, ‘KB4015221’, ‘KB4016637’, ‘KB4019474’, ‘KB4013198’, ‘KB4015219’, ‘KB4016636’, ‘KB4019473’, ‘KB4013429’, ‘KB4015217’, ‘KB4015438’, ‘KB4016635’, ‘KB4019472’, ‘KB4018466’)

# Get a list of computers to scan. Modify for your enviroment, use a CSV or whatever
$computers = Get-ADComputer -Filter * -SearchBase "OU=Workstations" | Sort-Object Name | Select-Object -ExpandProperty Name

# Fancy progress bar counter setup
$counter = 1
$counterMax = 1
$percent = 1
$counterMax = $computers.Count

# Loop throgh computer list
foreach($c in $computers)
{
    # Move the progress bar
    $percent = ($counter / $counterMax) * 100

    # Display a progress bar
    Write-Progress -Activity "Checking for EternalBlue HotFix installation ($counter / $counterMax)" -Status "Querying $c" -PercentComplete $percent
    
    # Check if computer is alive to save time
    if(Test-Connection -ComputerName $c -Count 1 -Quiet)
    {
        # Search for the HotFixes
        try
        {
            # Get a list of installed hotfixes and filter out what is not needed
            $hotfix = Get-HotFix -ComputerName $c -ErrorAction Stop | Where-Object {$hotfixes -contains $_.HotfixID} | Select-Object -property “HotFixID”
    
            # Check if installed hostix is on a list of EternalBlue hotfixes 
            if ($hotfix | Where-Object {$hotfixes -contains $_.HotfixID}) 
            {
                # If instlled write out in a fancy green
                Write-host “Computer - $c - Hotfix installed $($_.HotfixID)” -ForegroundColor Green 
            } 
            else 
            {
                # If not instlled write out in red
                Write-host “Computer - $c - Hotfix missing” -ForegroundColor Red
            }
        }
        catch
        {
            # If any error occures while getting a list of hotfixes (like WMI issues) write it out
            Write-Host "Computer - $c - Failed to query hotfix info" -ForegroundColor Gray
        }#end try
    }
    else
    {
        # If computer is not on the network or turned off write it out
        Write-Host "Computer - $c - Not alive" -ForegroundColor Gray
    }#end if

    # Increase the counter
    $counter += 1
}#end foreach