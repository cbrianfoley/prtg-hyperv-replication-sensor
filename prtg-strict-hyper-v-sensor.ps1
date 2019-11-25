<#
.USAGE
Steps
1.	Install Hyper-V tools on the server the probe is installed if it isn’t already (elevated powershell command): 

        Install-WindowsFeature -Name RSAT-Hyper-V-Tools –IncludeAllSubFeature

2.	Make the 32 bit version of PowerShell ‘RemoteSigned’ on the server the probe is installed on (elevated powershell command):

        %SystemRoot%\SysWOW64\WindowsPowerShell\v1.0\powershell.exe "Set-ExecutionPolicy RemoteSigned"

3.	Add service account as a member of the group Hyper-V Administrators on each VMHost 
        
        (this might be unnecessary if service account is a domain admin)

4.	Update this script and put a copy for each VMHost in the PRTG Network Monitor\Custom Sensors\EXEXML folder.

        Set HVhost to the hostname of one of the VMHost servers. 
        Set the upper and lower limit (LimitMaxError and LimitMaxWarning)

5.	Add a custom EXE Advanced sensor in PRTG
        Be sure to select the correct script under Sensor Settings -> Exe/Script
	    Select 'Use Windows Credentials of parent device' and make sure that account credentials are put in the parent group.

#>
$ErrorActionPreference = "SilentlyContinue"

# -----------------------

$HVhost = "VM-HOST01" #EDIT THIS LINE

# -----------------------

#This function returns the replication state of a vm. If replication for this VM is off, it returns nothing(null).
function Test-Replicationstate ($VMName){
    try{
        Get-VMReplication -ComputerName $HVhost | Where-Object Name -eq $VMName | Select VMName, VMId, ReplicationMode, ReplicationHealth, ComputerName,`
                                             PrimaryServer, ReplicaServer, LastReplicationTime, ReplicationState `
    }
    catch {
    }
}


$CurrentDate = (Get-Date)

$VMs = Get-VM -ComputerName $HVhost | Where-Object State -eq Running

#begin our xml file
$xmlstring = "<?xml version=`"1.0`"?>`n    <prtg>`n"


ForEach ($vm IN $VMs) {
    $replicationresult = Test-Replicationstate($vm.VMName)

#this if/else statement runs the vm object against the test-replicationstate function
#the vm might not be replicated, so test-replicationstate will then return a null value, and $totalminutes becomes 1441 (parsed by prtg as an error)
#if test-replicationstate returns replication info, it will calculate the time in minutes and set $totalminutes to that
    IF ($replicationresult -eq $null){
        $TotalMinutes = 1441
    }Else{ $TotalMinutes = (New-Timespan –Start $replicationresult.LastReplicationTime –End $CurrentDate).TotalMinutes
    }

    $xmlstring += "    <result>`n"
    $xmlstring += "        <channel>$($vm.VMName)</channel>`n"
    $xmlstring += "        <unit>Custom</unit>`n"
    $xmlstring += "        <CustomUnit>min</CustomUnit>`n"
    $xmlstring += "        <mode>Absolute</mode>`n"
    $xmlstring += "        <showChart>1</showChart>`n"
    $xmlstring += "        <showTable>1</showTable>`n"
    $xmlstring += "        <float>0</float>`n"
    $xmlstring += "        <value>$(IF ($TotalMinutes -lt 1) {"0"} ELSEIF ($TotalMinutes -gt 1440){"1441"} ELSE {($TotalMinutes.ToString("#"))})</value>`n"
    $xmlstring += "        <LimitMaxError>1440</LimitMaxError>`n"
    $xmlstring += "        <LimitMaxWarning>60</LimitMaxWarning>`n"
    $xmlstring += "        <LimitWarningMsg>Hyper-V Replication for this VM is in Warning state</LimitWarningMsg>`n"
    $xmlstring += "        <LimitErrorMsg>Hyper-V Replication failed for this VM and is in Critical state</LimitErrorMsg>`n"
    $xmlstring += "        <LimitMode>1</LimitMode>`n"
    $xmlstring += "    </result>`n"
 }

$xmlstring += "    </prtg>"

Write-Host $xmlstring