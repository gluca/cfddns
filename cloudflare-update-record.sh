#!/bin/bash

# CHANGE THESE
auth_email="user@example.com"
auth_key="c2547eb745079dac9320b638f5e225cf483cc5cfdda41" # found in cloudflare account settings
zone_name="example.com"
record_name="www.example.com"

ip=$(curl -s http://ipv4.icanhazip.com)
ip_file="ip.txt"
log_file="cloudflare.log"

echo "[$(date)] - Check Initiated" >> $log_file

if [ -f $ip_file ]; then
        old_ip=$(cat $ip_file)
        if [ $ip == $old_ip ]; then
                echo "IP has not changed."
                exit 0
        fi
else
        echo "$ip" > $ip_file
fi

zone_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone_name" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )

record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record_name" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*')

curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" --data "{\"id\":\"$zone_identifier\",\"type\":\"A\",\"name\":\"$record_name\",\"content\":\"$ip\"}" -o /dev/null

if [ $? -eq 0 ]; then
    echo "[$(date)] - IP changed to: $ip" >> $log_file
    echo "IP changed to: $ip"
else
    echo "[$(date)] - API UPDATE FAILED" >> $log_file
    echo "API UPDATE FAILED."
fi