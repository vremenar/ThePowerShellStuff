# U slijedečoj liniji promijenit do CSV-a sa listom servera, prva linija u datoteci se mora zvati Servers
$serverListFile = "D:\servers.csv"

# U slijedečoj liniji stavi gdje da ti iskrca CSV s listom servera i IP adresa
$outputFile = "D:\servers-with-ip.csv"

$serverList = Import-Csv -Path $serverListFile -Encoding UTF8

"Server;IP" | Out-File -FilePath $outputFile -NoClobber -ErrorAction SilentlyContinue

foreach ($server in $serverList) {
    $serverName = $server.Server
    $serverRecords = Resolve-DnsName -Name $serverName -Type A | Select-Object IPAddress
    #Resolve-DnsName -Name $serverName -Type A | Select-Object IPAddress
    foreach ($dnsRecord in $serverRecords) {
        $serverIP = $dnsRecord.IPAddress
        if ($serverIP -ne $null) {
            "$serverName;$serverIP" | Out-File -FilePath $outputFile -Append
        }
        $serverIp = $null
    }
}