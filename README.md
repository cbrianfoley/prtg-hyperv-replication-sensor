# prtg-hyperv-replication-sensor
Sensor for monitoring Hyper-V replication using PRTG. Written in powershell, it polls a VMHost and exports the information in xml format for PRTG to parse.

USAGE

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
