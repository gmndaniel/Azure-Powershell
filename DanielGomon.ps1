function New-ManyUsers ($tot_users) {
    $PasswordProfile = New-Object `
    -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
    $PasswordProfile.Password = "Av3rYc0Mpl3#P455woRd"

    for ($i=1; $i -le $tot_users; $i++) {
        $params = @{
            AccountEnabled = $true
            DisplayName = "Test User " +$i
            PasswordProfile = $PasswordProfile
            UserPrincipalName = "testuser" + $i + "@gmndanielgmail.onmicrosoft.com"
            MailNickName = "testuser"
        }
        New-AzureADUser @params
    }
}

######################################################################

function Remove-AllTestUsers {
    Get-AzureADUser -Filter "startswith(MailNickName,'testuser')" | Remove-AzureADUser
}

######################################################################

function New-ActiveDirectorySecurityGroup ($group_name) {
    New-AzureADGroup -DisplayName $group_name -MailEnabled $false -SecurityEnabled $true -MailNickName "VaronisADG"
}


######################################################################

function Write-CustomLogFile ($user, $group, $status) {
    $message = $timestamp + `
    " ADDING: " + $user + `
    ", TO GROUP: " + $group.DisplayName + `
    ", STATUS: " + $status

    Write-ToLog -message $message
}

######################################################################

function Write-ToLog ($message)  {
    $Logfile = $PSScriptRoot + "\task_logger.log"
    $time = Get-Date -Format HH:mm:ss
    $date = Get-Date -Format dd-MM-yyyy
    $timestamp = "[" + $time + " " + $date + "]"
    [string]$logstring = $timestamp + " " + $message
    
    Add-content $Logfile -value $logstring
}

######################################################################

function Add-SingleUserToActiveDirectorySecurityGroup ($user, $group) {
    
    $groupId = ($group).ObjectId
    $userId = (Get-AzureADUser -Filter "startswith(DisplayName,'$user')").ObjectId

    if (!$userId) {
        Write-ToLog -message ("ERROR: USER $user NOT FOUND")
    }
    elseif (!$groupId) {
        Write-ToLog -message ("ERROR: GROUP $group NOT FOUND")
    }
    else {
        $groupMembers = Get-AzureADGroupMember -ObjectId $groupId -All $true
        $existingMember =  $groupMembers | Where-Object { $_.ObjectId -eq $userId }

        $status = "Failed"
        if(!$existingMember){
            Add-AzureADGroupMember -ObjectId $groupId -RefObjectId $userId
            $status = "Succeeded"
        }
        Write-CustomLogFile -user $user -group $group -status $status 
    }
}


######################################################################

function Add-UsersToActiveDirectorySecurityGroup ($group_name, $tot_users) {
    $group = (Get-AzureADGroup -Filter "DisplayName eq '$group_name'")
  
    for ($i=1; $i -le $tot_users; $i++) {
        Write-Output $i
        $user = "Test User " + $i
        Add-SingleUserToActiveDirectorySecurityGroup -user $user -group $group
    }
}

######################################################################

function Remove-AllUsersFromActiveDirectorySecurityGroup ($name) {

    $group = (Get-AzureADGroup -Filter "DisplayName eq '$name'").ObjectId
    Get-AzureADGroupMember -ObjectId $group | `
    ForEach-Object {Remove-AzureADGroupMember -ObjectId $group -MemberId $_.ObjectId}
}

######################################################################

Clear-Host

$TOTAL_USERS = 20
New-ManyUsers -tot_users $TOTAL_USERS
New-ActiveDirectorySecurityGroup -group_name “Varonis Assignment2 Group”
Add-UsersToActiveDirectorySecurityGroup -group_name “Varonis Assignment2 Group” -tot_users $TOTAL_USERS



