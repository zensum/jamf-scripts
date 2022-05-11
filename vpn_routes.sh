#!/usr/bin/bash

CONENCTED=$1

interface=`ifconfig | grep -A 1 POINTOPOINT | grep ppp | awk {'print $1'} | sed -r 's/[:]+//g'`

if [[ ! -n $interface ]]; then
    echo "Found no interface to route through"
    exit 1
fi

gateway=`ifconfig | grep -A 1 POINTOPOINT | grep -A 1 $interface | grep -E "inet " | awk {'print $2'}`


addresses=()
addresses+=("35.204.118.71") # add reports
addresses+=("195.238.77.196") # callmaker_sftp_server
addresses+=(`nslookup api.zensum.se | grep "Address: " | awk {'print $2'}`) # Sverker SE
addresses+=(`nslookup a.zensum.se | grep "Address: " | awk {'print $2'}`) # Freja SE
addresses+=(`nslookup api.zensum.no | grep "Address: " | awk {'print $2'}`) # Sverker NO
addresses+=(`nslookup a.zensum.no | grep "Address: " | awk {'print $2'}`) # Freja NO
addresses+=(`nslookup zensum.eu.auth0.com | grep "Address: " | awk {'print $2'}`) # Auth0
addresses+=("192.168.110") # Stockholm internal CIDR same as 192.168.110.0/24
addresses+=("10.0.1") # Uppsala internal CIDR

routetable=`netstat -rn`

for a in "${addresses[@]}"
do
    route_extists=`echo $routetable | grep $a | grep $interface`

    if [[ -n $CONENCTED ]]; then
        # adding routes
        if [[ -n $route_extists ]]; then
            echo "Route already exists for $a through $gateway on interface $interface \n"
        else
            echo "Adding $a route through $gateway on interface $interface"
            route -n add -net $a $gateway
            echo
        fi
    else
        # removing routes
        if [[ ! -n $route_extists ]]; then
            echo "No route exists for $a through $gateway on interface $interface \n"
        else
            echo "Deleting $a route through $gateway on interface $interface"
            route -n delete -net $a -interface $interface
            echo
        fi
    fi
done
