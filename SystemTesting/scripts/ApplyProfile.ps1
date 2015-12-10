########################################################################
# Copyright (C) 2012 VMWare, Inc.
# All Rights Reserved
#
########################################################################
#
# This script will apply ESXi image files to a host.
#
########################################################################

param($server, $user, $password, $depot, $imgtype, $targethost)

$bindingFlags = [Reflection.BindingFlags] "Instance,NonPublic,GetField"
$objectRef = $host.GetType().GetField("externalHostRef", $bindingFlags).GetValue($host)
$bindingFlags = [Reflection.BindingFlags] "Instance,NonPublic,GetProperty"
$consoleHost = $objectRef.GetType().GetProperty("Value", $bindingFlags).GetValue($objectRef, @())

# Add console object type check
if ( $consoleHost.GetType().FullName -eq "Microsoft.PowerShell.ConsoleHost" )
{
  [void] $consoleHost.GetType().GetProperty("IsStandardOutputRedirected", $bindingFlags).GetValue($consoleHost, @())
  $bindingFlags = [Reflection.BindingFlags] "Instance,NonPublic,GetField"
  $field = $consoleHost.GetType().GetField("standardOutputWriter", $bindingFlags)
  $field.SetValue($consoleHost, [Console]::Out)
  $field2 = $consoleHost.GetType().GetField("standardErrorWriter", $bindingFlags)
  $field2.SetValue($consoleHost, [Console]::Out)
}

Set-ExecutionPolicy Unrestricted  -Force

#
# Add the required snapins.
#
Add-PSSnapin  VMware.VimAutomation.Core
Add-PSSnapin  VMware.DeployAutomation
Add-PSSnapin  Vmware.ImageBuilder


Write-Host "INFO : Connecting host $Server ..."
# Connect the VI server.
$connection = Connect-Viserver -Server $server -username $user -password $password -ErrorVariable scriptErrors
if (-not $connection) {
   Write-Host "FAIL - Failed to connect to vCentre server $server with Username : $User Password : $Password"
   Write-Host "$scriptErrors"
   exit
}

# Adding code to bypass certificate validation
$deploynosignaturecheck = $true

Write-Host  "INFO : Adding software depot..$Depot "
$addedDepot = Add-EsxSoftwareDepot $Depot
if(-not $addedDepot) {
  Write-Host "ERROR : Could not able to add the depot $Depot"
  exit
}

if (-not $imgtype) {
   $imgtype = "*standard*";
}

#$pr = Get-DeployRule "My-Profile-Rule"
#$ip = $pr.ItemList[0]

#$ip1  = Get-EsxImageProfile
#$ip1

Write-Host  "Getting ESX image profile $imgtype"

$ip = Get-EsxImageProfile -Name $imgtype
$ip

#Write-Host "INFO:  ESX Image Profile: $ip"

if (-not $ip) {
  Write-Host "ERROR : Could not get the image profile"
} else {
  Write-Host "INFO : Successfully got the image profile."
}

Write-Host "INFO : targethost $targethost"

#$ht = (Get-VMHost "$targethost")
Apply-ESXImageProfile -ImageProfile $ip $targethost -ErrorVariable scriptErrors

Write-Host "INFO :Apply-ESXImageProfile $targethost "
