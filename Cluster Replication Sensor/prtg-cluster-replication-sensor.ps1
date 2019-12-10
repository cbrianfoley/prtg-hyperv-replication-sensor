<#

prtg-cluster-replication-sensor.ps1
Script to get replication status of vms. Currently hardcoded to warn at 60 minutes and error at 24 hours

.USAGE
Steps
1.	Install Hyper-V tools and failover clustering features on the server the probe is installed if it isn’t already (elevated powershell command): 

        Install-WindowsFeature -Name RSAT-Hyper-V-Tools –IncludeAllSubFeature
        Install-WindowsFeature -Name RSAT-Clustering

2.	Make the 32 AND 64 bit version of PowerShell ‘RemoteSigned’ on the probe server (elevated powershell command):

        %SystemRoot%\SysWOW64\WindowsPowerShell\v1.0\powershell.exe "Set-ExecutionPolicy RemoteSigned"
        %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe "Set-ExecutionPolicy RemoteSigned"

3.	Add service account as a member of the group Hyper-V Administrators on each host 
        
        (this might be unnecessary if service account is a domain admin)

4.	Update this script and put a copy in the PRTG Network Monitor\Custom Sensors folder.

        Set ClusterName to your cluster name

5.  Due to how PRTG behaves, it can only call the 32 bit version of powershell, so we have to cheat/wrapper. Create a new .ps1 script with only one line
        
        C:\windows\sysnative\windowspowershell\v1.0\powershell.exe -file "C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML\<thispowershellscript>.ps1"

6.	Add a custom EXE Advanced sensor in PRTG
        Be sure to select the correct script under Sensor Settings -> Exe/Script (we are selecting the wrapper one-liner)
	    Select 'Use Windows Credentials of parent device' and make sure that account credentials are put in the parent group.

#>

# -----------------------

$ClusterName = "CLUSTER-INT1-19" #EDIT THIS LINE

# -----------------------

Import-Module FailoverClusters

$ClusterNodes = (Get-Cluster -Name $ClusterName | Get-ClusterNode)

$CurrentDate = (Get-Date)

#begin our xml file header
$xmlstring = "<?xml version=`"1.0`"?>`n"
$xmlstring += "    <prtg>`n"

ForEach ($node IN $ClusterNodes) {
    
    $VMs = Get-VM -ComputerName $node.Name | Where-Object State -eq 'Running'

    ForEach ($vm in $VMs){
        $replicationresult = Get-VMReplication -ComputerName $node | Where-Object Name -eq $vm | Select VMName, VMId, ReplicationMode, ReplicationHealth, ComputerName

        #this if/else statement runs the vm object against the test-replicationstate function
        #the vm might not be replicated, so test-replicationstate will then return a null value, and $totalminutes becomes 1441 (parsed by prtg as an error)
        #if test-replicationstate returns replication info, it will calculate the time in minutes and set $totalminutes to that
        If ($replicationresult -eq $null){
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
 }

$xmlstring += "    </prtg>"

Write-Host $xmlstring