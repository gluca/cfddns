#!/bin/bash

ip_file="ip.txt"
ip=$(curl -s http://ipv4.icanhazip.com)
log_file="cloudflare.log"

zone_identifier="ZONE IDENTIFIER"
record_identifier="RECORD IDENTIFIER"
record_name="RECORD NAME"

echo "[$(date)] - Check Initiated" > $log_file

if [ -f $ip_file ]; then
        old_ip=$(cat $ip_file)
        if [ $ip == $old_ip ]; then
                echo "IP has not changed."
                exit 0
        fi
else
        echo "$ip" > $ip_file
fi

curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" -H "X-Auth-Email: user@example.com" -H "X-Auth-Key: c2547eb745079dac9320b638f5e225cf483cc5cfdda41" -H "Content-Type: application/json" --data "{\"id\":\":zone_identifier\",\"type\":\"A\",\"name\":\"$record_name\",\"content\":\"$ip\"}" -o /dev/null

if [ $? -eq 0 ]; then
    echo "[$(date)] - IP changed to: $ip" > $log_file
    echo "IP changed to: $ip"
else
    echo "[$(date)] - API UPDATE FAILED WTF SON" > $log_file
    echo "API UPDATE FAILED WTF SON."
fi