# TheStuff
Random stuff for projects I do, did or will do

# Check-EternalBlueHotfix.ps1
This script will check if a HotFix (MS17-010) for EternalBlue exploit (WannaCry ransomware vector) is installed.

The script checks if a correct KB is installed on the computer. The list of KB's is refreshed on 17.05.2017. Basically it loads a list of computers (in the script an AD is used), loops through the list of computers, checks if they are acceible and comapres the list of installed hotfixes with a list of KB's that resolve SMB vulnerability which EternalBlus and WannaCry exploit.

If a log to file is needed please you could use a simple Out-File or something you prefer.

# Move-ComputerToOu.ps1
Moving a computer account from default location in Active Directory (OU=Computers) to propper OU for small organizations can be done manually. But in the larger organizations it can be a lot of repetitive manual work. For this reason I have creted this cmdlet which will add computer to proper group (in my company for printer deployment) and move it to propper OU. 

If the parameters are different for your organization you will have to change lines 20, 21, 22 and 151, 163 and 175. Also if you don't need adding computers to group comment out lines form 131 to 148.
