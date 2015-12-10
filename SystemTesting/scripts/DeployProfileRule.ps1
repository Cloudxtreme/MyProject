########################################################################
# Copyright (C) 2012 VMWare, Inc.
# All Rights Reserved
#
########################################################################
#
# This script deploys a rule for all the hosts with a image profile.
#
########################################################################

param($server, $user, $password, $depot, $imgtype, $rulename, $hostprofile, $inventory, $targethost, $rulepattern, $folder, $cluster, $cleanuphostname)

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


$deploynosignaturecheck = $true
Write-Host "INFO : Connecting host $Server ..."
# Connect the VI server.
$connection = Connect-Viserver -Server $server -username $user -password $password -ErrorVariable scriptErrors
if (-not $connection) {
   Write-Host "FAIL - Failed to connect to vCentre server $server with Username : $User Password : $Password"
   Write-Host "$scriptErrors"
   exit
}

# Adding code to bypass certificate validation
#$deploynosignaturecheck = $true

#cleanup host based on user input
if ($Targethost) {
   $cleanuphostname = $Targethost;
   Write-Host "INFO : Remove host $cleanuphostname from $Server if exists ..."
   Remove-VMHost $cleanuphostname -Confirm:$false -ErrorAction SilentlyContinue
}

if ($folder) {
  $fd = Get-Folder -Server $server  -Name $folder
  if ($fd) {
     Write-Host "INFO : Folder $fd  at $Server ..."
  } else {
    $fd = Get-Folder -NoRecursion | New-Folder -Name $folder
    Write-Host "INFO : Create  $fd at $Server ..."
  }
}

if ($inventory) {
  $inv = Get-Datacenter -Server $server -Name $inventory
  if( (-not $inv) -and ($fd)) {
    $inv = New-Datacenter -Location $fd -Name $inventory
  }
  if( (-not $inv) -and (-not $fd) ) {
    $inv = New-Datacenter -Server $server -Name $inventory
  }
  if($inv) {
     Write-Host "INFO:  DataCenter $inventory exists at $server"
  } else {
     Write-Host "INFO:  Can't create DataCenter  $inventory at $server "
     exit
  }
}
#$cluster = "Profile-Cluster"
if ($cluster) {
  $cl = Get-Cluster -Server $server -Name $cluster
  if(-not $cl) {
    $cl = New-Cluster -Location $inv -Name $cluster
  }
  if($cl) {
     Write-Host "INFO:  Cluster $cluster exists at $server"
  } else {
     Write-Host "INFO:  Can't create Cluster  $cluster at $server "
     exit
  }
}

Write-Host  "INFO : Folder .. $fd "
Write-Host  "INFO : DataCenter .. $inv "
Write-Host  "INFO : Cluster .. $cl "
Write-Host  "INFO : Adding software depot.. "
$addedDepot = Add-EsxSoftwareDepot $Depot
if(-not $addedDepot) {
  Write-Host "ERROR : Could not able to add the depot $Depot"
  exit
}

if (-not $imgtype) {
   $imgtype = "*standard*";
}

Write-Host  "Getting ESX image profile $imgtype"
$cmd = "Get-EsxImageProfile -Name $imgtype"
Write-Host "INFO:  ESX Image Profile: $cmd"

$ip = Get-EsxImageProfile -Name $imgtype

#$pr = Get-DeployRule $rulename
#$ip = $pr.ItemList[0]

if (-not $ip) {
   Write-Host "ERROR : Could not able to get the image profile of $imgtype"
} else {
   Write-Host "INFO : Successfully got the image profile $ip."
}

if ($hostprofile) {
   Write-Host  "Verify if host profile $hostprofile exists"
   $hp = Get-VMHostProfile $hostprofile
   if (-not $hp) {
      Write-Host "ERROR : hostprofile $hostprofile does not exist"
      exit
   } else {
     Write-Host "INFO : Successfully got the hostprofile $hostprofile."
   }
}

Write-Host "INFO : Creating Rule with the image profile."
Remove-DeployRule -Delete $rulename -ErrorAction SilentlyContinue

if ((-not $hp) -and (-not $rulepattern) -and (-not $inventory)) {
  Write-Host "INFO :  1  "
  New-DeployRule -Name $rulename  -Item $ip -AllHosts
} elseif ((-not $hp) -and (-not $rulepattern) -and ($inventory) -and (-not $cluster) ) {
  Write-Host "INFO :  2  "
  New-DeployRule -Name $rulename  -Item $ip,$inv -AllHosts
} elseif ((-not $hp) -and ($rulepattern) -and (-not $inventory)) {
  Write-Host "INFO :  3  "
  New-DeployRule -Name $rulename  -Item $ip -Pattern $rulepattern
} elseif ((-not $hp) -and (-not $rulepattern) -and ($cluster) ) {
  Write-Host "INFO :  3.1  "
  New-DeployRule -Name $rulename  -Item $ip,$cl  -AllHosts
} elseif ((-not $hp) -and ($rulepattern) -and ($inventory)) {
  Write-Host "INFO :  4  "
  New-DeployRule -Name $rulename  -Item $ip,$inv -Pattern $rulepattern
} elseif (($hp) -and (-not $rulepattern) -and (-not $inventory)) {
  Write-Host "INFO :  5  "
  New-DeployRule -Name $rulename  -Item $ip,$hp -AllHosts
} elseif (($hp) -and (-not $rulepattern) -and ($inventory)) {
  Write-Host "INFO :  6  "
  New-DeployRule -Name $rulename  -Item $ip,$inv,$hp -AllHosts
} elseif (($hp) -and ($rulepattern) -and (-not $inventory)) {
  Write-Host "INFO :  7  "
  New-DeployRule -Name $rulename  -Item $ip,$hp -Pattern $rulepattern
} elseif (($hp) -and ($rulepattern) -and ($inventory)) {
  Write-Host "INFO :  8  "
  New-DeployRule -Name $rulename  -Item $ip,$inv,$hp -Pattern $rulepattern
}

# Clearing all rules.
# This need some refinement.
Write-Host "INFO : Clearing all the rules."
Set-DeployRuleSet -clear

Write-Host  "INFO : Adding rule $rulename to the ruleset"
Add-DeployRule -deployRule $rulename

Write-Host  "INFO : Checking whether the rule is added or not..."
$rule = Get-deployRuleSet

$rulename1 =  $Rule.RuleList[0].Name

Write-Host  "INFO: $rulename1 Deployed rule: $rulename"

if ($rule.RuleList[0].Name-ne $rulename) {
   Write-Host  "ERROR : Could not find the rule with name $rulename in the ruleset."
   exit
} else {
   Write-Host "PASS: Successfully added rule."
}

