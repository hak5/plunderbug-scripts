#!/bin/bash
# Plunder Bug
# (C) Hak5 2019
#
# Bash mute script that manages iptables for the bug interface
# used to prevent the capture host from sending data over the wire the bug is tapping

OS=0

function banner(){
  echo " ###########################################"
  echo " # | \ /   Plunder Bug by Hak5             #"
  echo " # \ O.o                                   #"
  echo " #  ( _ )\  Bug Interface Mute Script      #"
  echo " #  '' ''¿                                 #"
  echo " ###########################################"
}

function usage() {
  echo "Usage: sudo ./plunderbug.sh"
  echo "              --mute                     Mute plunder bug interface and exit"
  echo "              --unmute                   Unmute plunder bug interface and exit"
}

function iptables_check() {
  if [[ -z $(which iptables) ]]; then
    echo "iptables required to mute interface"
  fi
}

function os_check() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "\nOSX Detected\n"
    OS=1
  elif [[ "$OSTYPE" == "cygwin" ]]; then
    err "Cygwin not supported"
  else
    OS=0
    iptables_check
  fi
}

function micdrop(){
  echo "Exited"
  exit $1
}

function err() {
  echo "[FATAL] $1"
  QUIT=1
  micdrop 1
}

function root_check() {
  if [[ "$EUID" -ne 0 ]]; then
    echo "Please re-run as root"
    usage
    micdrop 1
  fi
}

function wait_for_bug_connection() {
  printf "%s" 'Waiting for a plunder bug to be connected...'
  while [[ -z $IFACE ]]; do
    printf "%s" .
    if [[ "$OS" -eq 1 ]]; then
      IFACE=$(ifconfig | grep 00:13:37 -B2 | head -1 | awk {'print $1'} | sed 's/ *:.*//')
    else
      IFACE=$(ifconfig|grep 'HWaddr 00:13:37'|cut -d ' ' -f1)
    fi
    sleep 1
  done
  echo -e "\n\n[$IFACE] Plunder Bug connected\n"
}

function check_ip6tables_rule_exists(){
  if [[ -z $(ip6tables -vL|grep $IFACE) ]];then
    echo 1
  else
    echo 0
  fi
}

function add_rule_to_ip6tables() {
  pre_existing_rule=$(check_ip6tables_rule_exists)
  if [[ "$pre_existing_rule" -eq 1 ]];then
    printf "\t%s" "[+] Adding ip6tables rule..."
    ip6tables -A OUTPUT -o $IFACE -j DROP && echo "Success" || err "failed to add rule to ip6tables"
  else
    echo "IPv6 Mute rule already exists on system..."
  fi
}

function check_iptables_rule_exists(){
  if [[ -z $(iptables -vL|grep $IFACE) ]];then
    echo 1
  else
    echo 0
  fi
}

function add_rule_to_iptables() {
  pre_existing_rule=$(check_iptables_rule_exists)
  if [[ "$pre_existing_rule" -eq 1 ]];then
    printf "\t%s" "[+] Adding iptables rule..."
    iptables -A OUTPUT -o $IFACE -j DROP && echo "Success" || err "failed to add rule to iptables"
  else
    echo "IPv4 Mute rule already exists on system..."
  fi
}

function remove_rule_from_ip6tables() {
  pre_existing_rule=$(check_ip6tables_rule_exists)
  if [[ "$pre_existing_rule" -eq 0 ]];then
    printf "\t%s" "[-] Removing ip6tables rule..."
    ip6tables -D OUTPUT -o $IFACE -j DROP && echo "Success" || err "failed to remove ip6tables rule"
  else
    echo "IPv6 Mute rule already removed from system..."
  fi
}

function remove_rule_from_iptables() {
  pre_existing_rule=$(check_iptables_rule_exists)
  if [[ "$pre_existing_rule" -eq 0 ]];then
    printf "\t%s" "[-] Removing iptables rule..."
    iptables -D OUTPUT -o $IFACE -j DROP && echo "Success" || err "failed to remove iptables rule"
  else
    echo "IPv4 Mute rule already removed from system..."
  fi
}

function disable_interface_in_networksetup() {
  BUGIFACE=$(ifconfig | grep 00:13:37 -B2 | head -1 | awk {'print $1'} | sed 's/ *:.*//')
  if [[ -n "$BUGIFACE" ]]; then
    BUGIFACENAME=$(networksetup -listnetworkserviceorder | grep $BUGIFACE -B1 | head -1 | sed 's/(.*)//' | cut -c2-)
    networksetup -setv4off "$BUGIFACENAME" || err "error disabling ipv4 on bug interface"
    networksetup -setv6off "$BUGIFACENAME" || err "error disabling ipv6 on bug interface"
  fi
}

function enable_interface_in_networksetup(){
  BUGIFACE=$(ifconfig | grep 00:13:37 -B2 | head -1 | awk {'print $1'} | sed 's/ *:.*//')
  if [[ -n "$BUGIFACE" ]]; then
    BUGIFACENAME=$(networksetup -listnetworkserviceorder | grep $BUGIFACE -B1 | head -1 | sed 's/(.*)//' | cut -c2-)
    networksetup -setdhcp "$BUGIFACENAME" || err "error enabling ipv4 on bug interface"
    networksetup -setv6automatic "$BUGIFACENAME" || err "error enabling ipv6 on bug interface"
  fi
}

function mute(){
  echo "[*] Muting plunder bug interface..."
  if [[ "$OS" -eq 0 ]]; then
    add_rule_to_iptables
    add_rule_to_ip6tables
  elif [[ "$OS" -eq 1 ]];then
    disable_interface_in_networksetup
  fi
  echo -e "[*] Mute complete\n"
}

function unmute() {
  echo "[*] Unmuting plunder bug interface... $IFACE"
  if [[ "$OS" -eq 0 ]]; then
    remove_rule_from_iptables
    remove_rule_from_ip6tables
  elif [[ "$OS" -eq 1 ]];then
    enable_interface_in_networksetup
  fi
  echo -e "[*] Unmute complete\n"
  QUIT=1
}

function cleanup() {
          echo -e "\n[!] Cleaning up..."
          unmute
}

##########################
# MAIN ENTRY
##########################
QUIT=0
# Validate args
banner

# Validate priv / iptables
root_check
os_check

if [[ -z "$2" ]]; then
  # Wait for device to be connected - no arg supplied for --mute/--unmute
  wait_for_bug_connection
else
  # Arg given for --mute/--unmute
  IFACE=$2
fi

# Handle modes
if [[ "$1" = "--unmute" ]]; then
  cleanup
  micdrop 0
elif [[ "$1" = "--mute" ]]; then
  mute
  micdrop 0
else
  usage
  micdrop 1
fi

# Wait for bug to be unplugged/ctrl-c - cleanup and exit
trap cleanup INT
micdrop 0
