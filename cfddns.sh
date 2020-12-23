#!/bin/bash

# CHANGE THESE
auth_email="example@mail.box"
auth_key="f33223caaddee44dede34bdbcdf12edff3eedaac1e3" # found in cloudflare account settings
zone_name=$2
record_name=$1

# MAYBE CHANGE THESE
ip=$(curl -s http://ipv4.icanhazip.com)
ip_file="my.ip"
id_zone="zone_$2.id"
id_record="record_$1.id"
log_file="cfddns.log"

# LOGGER
log() {
    if [ "$1" ]; then
        echo -e "[$(date)] - $1" >> $log_file
    fi
}

# SCRIPT START

log "Check Initiated"
log "Public address: $ip"
log "Updating $record_name for $zone_name"

if [ -f $ip_file ]; then
    old_ip=$(cat $ip_file)
    if [ $ip == $old_ip ]; then
        echo "IP has not changed."
        exit 0
    fi
fi

if [ -f $id_zone ] && [ $(wc -l $id_zone | cut -d " " -f 1) == 1 ]; then
    zone_identifier=$(head -1 $id_zone)
	log "Zone id (from cache): $zone_identifier"
else
    zone_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone_name" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1)
	log "Zone id: $zone_identifier"
    echo "$zone_identifier" > $id_zone
fi

if [ -f $id_record ] && [ $(wc -l $id_record | cut -d " " -f 1) == 1 ]; then
    record_identifier=$(head -1 $id_record)
	log "Record id (from cache): $record_identifier"
else
	record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record_name" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*' | head -1)
    log "Record id: $record_identifier"
    echo "$record_identifier" > $id_record
fi

update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" --data "{\"id\":\"$zone_identifier\",\"type\":\"A\",\"name\":\"$record_name\",\"content\":\"$ip\"}")

if [[ $update == *"\"success\":false"* ]]; then
    message="API UPDATE FAILED. DUMPING RESULTS:\n$update"
    log "$message"
    echo -e "$message"
    exit 1 
else
	log $update
    message="IP changed to: $ip"
    echo "$ip" > $ip_file
    log "$message"
    echo "$message"
fi