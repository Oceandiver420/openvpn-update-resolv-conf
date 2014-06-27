#!/bin/bash
#
# Parses DHCP options from openvpn to update resolv.conf
# To use set as 'up' and 'down' script in your openvpn *.conf:
# up /etc/openvpn/update-resolv-conf
# down /etc/openvpn/update-resolv-conf
#
# Used snippets of resolvconf script by Thomas Hood <jdthood@yahoo.co.uk>
# and Chris Hanson
# Licensed under the GNU GPL.  See /usr/share/common-licenses/GPL.
# 07/2013 colin@daedrum.net Fixed intet name
# 05/2006 chlauber@bnc.ch
#
# Example envs set from openvpn:
# foreign_option_1='dhcp-option DNS 193.43.27.132'
# foreign_option_2='dhcp-option DNS 193.43.27.133'
# foreign_option_3='dhcp-option DOMAIN be.bnc.ch'
# foreign_option_4='dhcp-option DOMAIN-SEARCH bnc.local'

set -e

## You might need to set the path manually here, i.e.
# RESOLVCONF=/usr/bin/resolvconf
RESOLVCONF=$(which resolvconf)
[ -x $RESOLVCONF ] || exit 0

case $script_type in

up)
   for optionname in ${!foreign_option_*} ; do
      option="${!optionname}"
      echo $option
      part1=$(echo "$option" | cut -d " " -f 1)
      if [ "$part1" == "dhcp-option" ] ; then
         part2=$(echo "$option" | cut -d " " -f 2)
         part3=$(echo "$option" | cut -d " " -f 3)
         if [ "$part2" == "DNS" ] ; then
            IF_DNS_NAMESERVERS="$IF_DNS_NAMESERVERS $part3"
         fi
         if [[ "$part2" == "DOMAIN" || "$part2" == "DOMAIN-SEARCH" ]] ; then
            IF_DNS_SEARCH="$IF_DNS_SEARCH $part3"
         fi
      fi
   done
   R=""
   for DS in $IF_DNS_SEARCH ; do
           R="${R}search $DS
"
   done
   for NS in $IF_DNS_NAMESERVERS ; do
           R="${R}nameserver $NS
"
   done
   #echo -n "$R" | $RESOLVCONF -p -a "${dev}"
   echo -n "$R" | $RESOLVCONF -a "${dev}.inet"
   ;;
down)
   $RESOLVCONF -d "${dev}.inet"
   ;;
esac