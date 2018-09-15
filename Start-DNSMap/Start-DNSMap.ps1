# Setup, change this to match your needs
$scriptLocation = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition # Do not change this if not neccesary
$file = "$scriptLocation\dns.txt" # Change this to your custom list of DNS addresses if needed
$domain = "microsoft.com" # The target! Change this to what you need

### No need to change anything below this line
# Set variables
$recordsMin = 0
$recordsMax = 0
$recordsCount = 0
$recordsProgress = 0  
$dnsServer = $null
$records = $null
    
# Find the fastest DNS server
# Try Google
try
{
    $gTime = $(Measure-Command -Expression {Resolve-DnsName -Name www.google.com -Server 8.8.8.8 -DnsOnly -QuickTimeout -ErrorAction Stop}).Milliseconds
    Write-Host "Google DNS response time: $gTime ms" -ForegroundColor Green
}
catch
{
    Write-Host "Google DNS not reacheable" -ForegroundColor Gray
    $gTime = 1000
}#end try

# Try CloudFlare
try
{   
    $cTime = $(Measure-Command -Expression {Resolve-DnsName -Name www.google.com -Server 1.1.1.1 -DnsOnly -QuickTimeout -ErrorAction Stop}).Milliseconds
    Write-Host "CloudFlare DNS response time: $cTime ms" -ForegroundColor Green
}
catch
{
    Write-Host "CloudFlare DNS not reacheable" -ForegroundColor Gray
    $cTime = 1000
}#end try

# Try Quad9
try
{   
    $qTime = $(Measure-Command -Expression {Resolve-DnsName -Name www.google.com -Server 9.9.9.9 -DnsOnly -QuickTimeout -ErrorAction Stop}).Milliseconds
    Write-Host "Quad9 DNS response time: $qTime ms" -ForegroundColor Green
}
catch
{
    Write-Host "Quad9 DNS not reacheable" -ForegroundColor Gray
    $qTime = 1000
}#end try


if(($gTime -lt $cTime) -and ($gTime -lt $qTime))
{
    $dnsServer = "8.8.8.8" # Google DNS
}
elseif(($cTime -lt $gTime) -and ($cTime -lt $qTime))
{
    $dnsServer = "1.1.1.1" # CloudFlare DNS
}
elseif(($qTime -lt $gTime) -and ($qTime -lt $cTime))
{
    $dnsServer = "9.9.9.9" # Quad9 DNS
}
else
{
    $dnsServer = $null # No public DNS available
}#end if

if($dnsServer -eq $null)
{
    Write-Host "No public DNS server available, using eth adapter set DNS server" -ForegroundColor Green
}
else
{
    Write-Host "Selected DNS server: $dnsServer" -ForegroundColor Green
}#end if
    
# Create dump folder
try
{
    New-Item -Path "$scriptLocation\dump" -ItemType Directory -ErrorAction SilentlyContinue
}
catch
{
    # Do nothing
}#end try
    
# Load DNS records to test
try
{
    $records = Get-Content -Path $file -ErrorAction Stop
    $recordsMax = $records.Count
}
catch
{
    $records = $null
    Write-Host "Failed to load DNS records from file $file" -ForegroundColor Red
}
    
# Try to find DNS records
if($records -ne $null)
{
    foreach($line in $records)  
    {
        $response = $null
        $ipAddress = $null
        $nameHost = $null

        $recordsProgress = [math]::Round((($recordsCount / $recordsMax) * 100),2)
        Write-Progress -Activity "Testing record: $line.$domain" -Status "Testing $recordsCount / $recordsMax ($recordsProgress%)" -Id 1 -PercentComplete $recordsProgress

        # Try the "live" record
        try
        {
            # Resolve DNS
            if($dnsServer -eq $null)
            {
                $response = Resolve-DnsName -Name "$line.$domain" -ErrorAction Stop # Use adapter set DNS server
            }
            else
            {
                $response = Resolve-DnsName -Name "$line.$domain" -Server $dnsServer -ErrorAction Stop # Use a fastest public DNS server
            }#end if

            foreach($r in $response)
            {
                $ipAddress = $r.IP4Address
                if($ipAddress -ne $null)
                {
                    Write-Host "Found IP for DNS record: $line.$domain" -ForegroundColor Green
                    Write-Host "Found IP: $ipAddress" -ForegroundColor Gray
                    "Found DNS record for $line.$domain" | Out-File -FilePath "$scriptLocation\dump\$domain.txt" -Append
                    "----------------------------------" | Out-File -FilePath "$scriptLocation\dump\$domain.txt" -Append
                    $($response) | Out-File -FilePath "$scriptLocation\dump\$domain.txt" -Append
                }#end if

                $nameHost = $r.NameHost
                if($nameHost -ne $null)
                {
                    Write-Host "Found additional host for DNS record: $line.$domain" -ForegroundColor Green
                    Write-Host "Found additional host: $nameHost" -ForegroundColor Gray
                    "Found DNS record for $line.$domain" | Out-File -FilePath "$scriptLocation\dump\$domain.txt" -Append
                    "----------------------------------" | Out-File -FilePath "$scriptLocation\dump\$domain.txt" -Append
                    $($response) | Out-File -FilePath "$scriptLocation\dump\$domain.txt" -Append
                }#end if
            }#end foreach            
        }
        catch
        {
            $response = $null
        }#end try

        $nameHost = $null
        $ipAddress = $null
        $response = $null
        $recordsCount += 1
    }#end foreach
}#end if

#Clean up
$response = $null
$filesMin = 0
$filesMax = 0
$filesCount = 0
$filesProgress = 0
[GC]::Collect()
