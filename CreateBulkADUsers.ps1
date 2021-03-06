Import-Module ActiveDirectory
$new_users = Import-Csv \\princeplc.com.kh\file-server\Software\Powershell\New_Users.csv
#$existing_users = Get-ADUser -Filter * | Select-Object SamAccountname
#$rootdomain = (Get-ADDomain).DistinguishedName
#$domain = (Get-ADDomain).DNSRoot

### $domain = "yourdomain.com"
$domain = "princebank.com.kh"

### Specify logfile location
$logfile = "\\princeplc.com.kh\file-server\Software\Powershell\logs.txt"


### Check if log file already exist
If(Test-Path $logfile)
{
    try{
        Clear-Content $logfile ### If exist then clear its content
    }
    catch{
        Write-Host "Unable to clear logs content"
    }
    
}
else 
{
    New-Item $logfile ### If not, then create a new log file
}


$fax = ""


foreach ($user in $new_users){
    
    $firstname = $user.firstname
    $lastname  = $user.lastname
    $displayname = $user.displayname
    $samaccountname = $user.samaccountname
    $emailaddress = "$samaccountname@$domain"
    $mobile = $user.mobile
    $title = $user.title
    $department = $user.department
    $division = $user.division
    $ou = $user.ou
    $oupath = $user.oupath
    $oucode = $user.oucode
    $branch = $user.branch
    $address = $user.address


    if(Get-ADUser -F {SamAccountName -eq $samaccountname}){
        Write-Host "$samaccountname is already exist in $domain" -ForegroundColor Yellow
    }

    else{

    try{

        if($oucode -ne ""){
            $fax = "yes"
            $template_user = "branchoffice.usertem"
            $default_groups = Get-ADUser -Identity "$template_user" -Properties memberof | Select-Object -ExpandProperty memberof
            $department = $ou
            $division = "$department Branch"
        }
        else{
            $template_user = "headoffice.usertempl"
            $default_groups = Get-ADUser -Identity "$template_user" -Properties memberof | Select-Object -ExpandProperty memberof
            $fax = ""
        }


        New-ADUser `
        -Name "$oucode$displayname" `
        -GivenName "$lastname" `
        -Surname "$firstname" `
        -SamAccountName "$samaccountname" `
        -UserPrincipalName "$samaccountname@$domain" `
        -DisplayName "$oucode$displayname" `
        -AccountPassword (ConvertTo-SecureString -AsPlainText "Hello@123" -Force) `
        -Path "$oupath" `
        -HomeDrive "I" `
        -HomeDirectory "\\princeplc.com.kh\file-server\Private\$samaccountname" `
        -EmailAddress "$emailaddress" `
        -Title "$title" `
        -Department "$department" `
        -Company "$division" `
        -Mobile "$mobile" `
        -Fax "$fax" `
        -Enabled $true `
        -ChangePasswordAtLogon $true `
        -ScriptPath "Logon.vbs" `
        -POBox "$displayname" `
        -StreetAddress "$address"


        $default_groups | Add-ADGroupMember -Members $samaccountname
        Write-Host "$samaccountname has been created successfully" -ForegroundColor Green
        }
    catch{
        Write-Host "$samaccountname creation failed" -ForegroundColor Red
        $messages = $_
    }
    Finally{
        $Time=Get-Date    
        "$Time - Error: $messages" | Out-File $logfile -Append
    }
    }
}
