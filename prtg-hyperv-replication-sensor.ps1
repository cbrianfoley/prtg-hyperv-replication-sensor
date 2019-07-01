$HVhost = "VM-HOST02"

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
