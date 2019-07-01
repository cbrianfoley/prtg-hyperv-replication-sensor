<#
.USAGE
Steps
1.	Install Hyper-V tools on the server the probe is installed if it isn’t already (elevated powershell command): 

        Install-WindowsFeature -Name RSAT-Hyper-V-Tools –IncludeAllSubFeature

2.	Make the 32 bit version of PowerShell ‘RemoteSigned’ on the server the probe is installed on (elevated powershell command):

	    %SystemRoot%\SysWOW64\WindowsPowerShell\v1.0\powershell.exe "Set-ExecutionPolicy RemoteSigned"

3.	Add service account as a member of the group Hyper-V Administrators on each VMHost 
    (this might be unnecessary if service account is a domain admin, but I’m not certain)

4.	Update this script and put a copy for each VMHost in the PRTG Network Monitor\Custom Sensors\EXEXML folder.

        Set HVhost to the hostname of one of the VMHost servers. 
        Set the upper and lower limit (LimitMaxError and LimitMaxWarning)

5.	Add a custom EXE Advanced sensor in PRTG
	    Be sure to select the correct script under Sensor Settings -> Exe/Script
	‘Security Context of probe service’ should work. If not, select 'Use Windows Credentials of parent device' and make sure that account credentials are put in the parent group.

#>

$HVhost = "VM-HOST02"

# -----------------------

$CurrentDate = (Get-Date)

$Results = Get-VMReplication -Computer $HVhost | Select VMName, VMId, ReplicationMode, ReplicationHealth, ComputerName,`
                                             PrimaryServer, ReplicaServer, LastReplicationTime, ReplicationState `
                                             | Where-Object ReplicationMode -eq "Primary"

$xmlstring = "<?xml version=`"1.0`"?>`n    <prtg>`n"

ForEach ($eachresult IN $Results) {

$TotalMinutes = (New-Timespan –Start $eachresult.LastReplicationTime –End $CurrentDate).TotalMinutes

$xmlstring += "    <result>`n"
$xmlstring += "        <channel>$($eachresult.VMname)</channel>`n"
$xmlstring += "        <unit>Custom</unit>`n"
$xmlstring += "        <CustomUnit>min</CustomUnit>`n"
$xmlstring += "        <mode>Absolute</mode>`n"
$xmlstring += "        <showChart>1</showChart>`n"
$xmlstring += "        <showTable>1</showTable>`n"
$xmlstring += "        <float>0</float>`n"
$xmlstring += "        <value>$(IF ($TotalMinutes -lt 1) {"0"} ELSE {($TotalMinutes.ToString("#"))} )</value>`n"
$xmlstring += "        <LimitMaxError>360</LimitMaxError>`n"
$xmlstring += "        <LimitMaxWarning>60</LimitMaxWarning>`n"
$xmlstring += "        <LimitWarningMsg>Hyper-V Replication for this VM is in Warning state</LimitWarningMsg>`n"
$xmlstring += "        <LimitErrorMsg>Hyper-V Replication failed for this VM and is in Critical state</LimitErrorMsg>`n"
$xmlstring += "        <LimitMode>1</LimitMode>`n"
$xmlstring += "    </result>`n"

 }

$xmlstring += "    </prtg>"

Write-Host $xmlstring