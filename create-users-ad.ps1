#region Connection to Remote Server
$Creds = Get-Credential -Credential "domain\user"
$Domain = "10.10.10.1"
$NewSession = New-PSSession -ComputerName $Domain -Credential $Creds
#endregion

#Import Modules
Import-Module -PSSession $NewSession -Name ActiveDirectory

#Import CSV
$ListOfUsers = Import-Csv -Path  "C:\Temp\file.csv"

foreach ($user in $ListOfUsers){
    $FirstName = $user.'FirstName'
    $LastName = $user.'LastName'
    $Username = $user.'Username'
    $Password = $user.'Password'
    $OU = $user.'OU'

    $UserProps = @{
        GivenName           = $FirstName
        Surname             = $LastName
        SamAccountName      = $Username
        UserPrincipalName   = "$FirstName.$LastName@domain.local"
        Name                = "$FirstName $LastName"
        Email               = "$FirstName.$LastName@domain.local"
        Path                = $OU
        AccountPassword     = (ConvertTo-SecureString $Password -AsPlainText -Force)
        Enabled             = $true
    }

    New-ADuser @UserProps
}




