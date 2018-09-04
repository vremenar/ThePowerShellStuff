# TheStuff
Random stuff for projects I do, did or will do

# Check-EternalBlueHotfix.ps1
This script will check if a HotFix (MS17-010) for EternalBlue exploit (WannaCry ransomware vector) is installed.

The script checks if a correct KB is installed on the computer. The list of KB's is refreshed on 17.05.2017. Basically it loads a list of computers (in the script an AD is used), loops through the list of computers, checks if they are acceible and comapres the list of installed hotfixes with a list of KB's that resolve SMB vulnerability which EternalBlus and WannaCry exploit.

If a log to file is needed please you could use a simple Out-File or something you prefer.
