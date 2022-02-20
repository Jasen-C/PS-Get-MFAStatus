# Author Jasen C
# Date 2/20/2022
# Description: Get all licensed O365/Azure AD users MFA status, the Default MFA method as well as any other 
# MFA methods configured on the accounts. Export the data to csv

#Inspiration taken from original script at https://lazyadmin.nl/powershell/list-office365-mfa-status-powershell/


# MSonline module required
# install-module MSonline
Connect-MsolService

$CSV  = "C:\temp\User-MFAStatus.csv"
Remove-Item $CSV
$MFAUserStatus = @()

# Get all enabled and licensed O365/Azure AD user accounts
$MsolUsers = Get-MsolUser -EnabledFilter EnabledOnly -All | Where-Object {$_.IsLicensed -eq $True} | Sort-Object UserPrincipalName
foreach ($MsolUser in $MsolUsers) {

#region DefaultMFA
# get the user accounts default MFA method and change the wording to something meaningful
$MFAMethodDefault = ""
$MFAMethodDefault = $MsolUser.StrongAuthenticationMethods | Where-Object {$_.IsDefault -eq $true} | Select-Object -ExpandProperty MethodType
  If (($MsolUser.StrongAuthenticationRequirements) -or ($MsolUser.StrongAuthenticationMethods)) {
    Switch ($MFAMethodDefault) {
        "OneWaySMS" { $MFAMethodDefault = "SMS token" }
        "TwoWayVoiceMobile" { $MFAMethodDefault = "Phone call verification" }
        "PhoneAppOTP" { $MFAMethodDefault = "Hardware token or authenticator app" }
        "PhoneAppNotification" { $MFAMethodDefault = "Authenticator app" }
            }
          }
        
#endregion

#region OtherMFA
# get all other MFA methods configured for the account and change the wording to something meaningful
# iterate through each configured item
    $MFAMethodOthers = @()
    $MFAMethodOthers = @($MsolUser.StrongAuthenticationMethods | Where-Object {$_.IsDefault -eq $false} | Select-Object -ExpandProperty MethodType)
    $Count = ""
    $Count = ($MFAMethodOthers).Count
    If (($MsolUser.StrongAuthenticationRequirements) -or ($MsolUser.StrongAuthenticationMethods)) {
      for ($i=0; $i -lt ($Count); $i++){   
              Switch ($MFAMethodOthers[$i]) {
                  "PhoneAppNotification" { $MFAMethodOther[$i] = "Authenticator app" }
                  "OneWaySMS" { $MFAMethodOthers[$i] = "SMS token" }
                  "TwoWayVoiceMobile" { $MFAMethodOthers[$i] = "Phone call verification" }
                  "PhoneAppOTP" { $MFAMethodOthers[$i] = "Hardware token or authenticator app" }
              }

      }
    }
#endregion


#region buildoject for each user account

  $object = [PSCustomObject]@{
    DisplayName       = $MsolUser.DisplayName
    UserPrincipalName = $MsolUser.UserPrincipalName
    Department        = $MsolUser.Department
    Office            = $MsolUser.Office
    MFAEnabled        = if ($MsolUser.StrongAuthenticationMethods) {$true} else {$false}
    MFAEnforced       = if ($MsolUser.StrongAuthenticationRequirements) {$true} else {"-"}

    MFATypeDefault           = $MFAMethodDefault

            MFATypeOther1           = $MFAMethodOthers[0]
            MFATypeOther2           = $MFAMethodOthers[1]
            MFATypeOther3           = $MFAMethodOthers[2]
            MFATypeOther4           = $MFAMethodOthers[3]
            MFATypeOther5           = $MFAMethodOthers[4]

   }

   $MFAUserStatus += $object

   #endregion
}

#export all the user details to csv for review
  $MFAUserStatus | Export-Csv $CSV -NoTypeInformation