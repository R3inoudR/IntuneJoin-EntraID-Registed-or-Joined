# Function to trigger MDM Enrollment for EntraID Joined devices
function Trigger-MDMEnrollmentForJoinedDevice {
    # Set MDM Enrollment URLs
    $key = 'SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo\*'
    $keyinfo = Get-Item "HKLM:\$key"
    $url = $keyinfo.name
    $url = $url.Split("\")[-1]
    $path = "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo\$url"

    New-ItemProperty -LiteralPath $path -Name 'MdmEnrollmentUrl' -Value 'https://enrollment.manage.microsoft.com/enrollmentserver/discovery.svc' -PropertyType String -Force -ErrorAction SilentlyContinue
    New-ItemProperty -LiteralPath $path -Name 'MdmTermsOfUseUrl' -Value 'https://portal.manage.microsoft.com/TermsofUse.aspx' -PropertyType String -Force -ErrorAction SilentlyContinue
    New-ItemProperty -LiteralPath $path -Name 'MdmComplianceUrl' -Value 'https://portal.manage.microsoft.com/?portalAction=Compliance' -PropertyType String -Force -ErrorAction SilentlyContinue

    # Attempt to trigger AutoEnroll and capture the exit code
    C:\Windows\system32\deviceenroller.exe /c /AutoEnrollMDM
    Write-Host "Intune onboarding done for EntraID Joined device."
}

# Function to trigger MDM Enrollment for EntraID Registered devices
function Trigger-MDMEnrollmentForRegisteredDevice {
    Write-Host "Device is EntraID Registered. Initiating MDM enrollment..."

    # Open the settings page for "Access work or school"
    Start-Process "ms-settings:workplace" # Opens the settings page

    # Optionally, you can provide further instructions
    Write-Host "Please complete the MDM enrollment manually via the settings page."
}

# Check if the device is EntraID Joined
$aadJoined = dsregcmd /status | Select-String "AzureAdJoined : YES"

if ($aadJoined) {
    Write-Host "Device is EntraID Joined."
    Trigger-MDMEnrollmentForJoinedDevice
} else {
    # Check if the device is EntraID Registered
    $azureAdStatus = Get-WmiObject -Namespace "root\cimv2\mdm\dmmap" -Class "MDM_DevDetail_Ext01" | Select-Object -ExpandProperty DevDetail_DeviceID
    
    if ($azureAdStatus) {
        Write-Host "Device is EntraID Registered."
        Trigger-MDMEnrollmentForRegisteredDevice
    } else {
        Write-Host "Device is neither EntraID Joined nor EntraID Registered. Exiting script."
    }
}
