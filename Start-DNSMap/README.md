# Start-DNSMap.ps1
This script will test if DNS records exist. Edit the script to enter the domain you wish to test. The script will try to find a fastest public DNS server (Google, CloudFlare, Quad9) and if public DNS is not available it will use the DNS setting from the eth adapter. Dumps will be saved to the /dump/ folder.

# DNS.txt
This file contains most used DNS records. It should be in the same location as the script, or you can edit the script to use your own DNS list to test.
