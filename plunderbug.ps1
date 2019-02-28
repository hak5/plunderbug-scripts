<#

 Plunder Bug
 (C) Hak5 2019
 Powershell mute script that manages NetAdapterBinding for the bug interface
 used to prevent the capture host from sending data over the wire the bug is tapping

#>

param([string]$mode)

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $mode" -Verb RunAs; exit }


function banner {
  " ###########################################"
  " # | \ /   Plunder Bug by Hak5             #"
  " # \ O.o                                   #"
  " #  ( _ )\  Windows Bug Mute Script        #"
  " #  '' ''¿                                 #"
  " ###########################################"
}

function usage {
  "Usage: plunderbug.ps1 <mode>"
  "              mute                     Mute plunder bug interface and exit"
  "              unmute                   Unmute plunder bug interface and exit"
}

function mute($iface_name) {
  "Disabling IPv4 on bug interface $iface_name ..."
  
  Disable-NetAdapterBinding -Name $iface_name -ComponentID ms_tcpip
  
  "Disabling IPv6 on bug interface $iface_name ..."
  
  Disable-NetAdapterBinding -Name $iface_name -ComponentID ms_tcpip6

  "Mute complete"
}

function unmute($iface_name) {
  "Enabling IPv4 on bug interface $iface_name ..."
  
  Enable-NetAdapterBinding -Name $iface_name -ComponentID ms_tcpip
  
  "Enabling IPv6 on bug interface $iface_name ..."
  
  Enable-NetAdapterBinding -Name $iface_name -ComponentID ms_tcpip6

  "Unmute complete"
}

banner
"Starting plunderbug mute script..."
"Waiting for the plunderbug to be connected..."
$iface_name = $null
$name = $null 
while ($name -eq $null){

  $name=Get-NetAdapter| Where-Object {$_.MacAddress -match "00-13-37*"} | Select Name | Format-Table -hidetableheader
  $tmp=$name | Out-String
  $iface_name=$tmp.trim()

  Start-Sleep -Seconds 1
}
"Interface Detected... $iface_name"

if ( $mode -eq "mute" ){
  mute $iface_name
  pause
  exit
}

if ( $mode -eq "unmute") {
  unmute $iface_name
  pause
  exit
}

usage
pause
