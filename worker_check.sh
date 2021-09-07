#!/bin/bash
curl -s -w '\n%{http_code}' -H 'Content-Type: application/json' -H 'Authorization: Bearer {$apikey}' https://api2.hiveos.farm/api/v2/farms/{$farmid}/workers/{$workerid} | sed 's/^000-H//g;/^200-H/d;/^200$/d' | jq '.' > /tmp/worker_check
worker_status=$( grep '"online": ' /tmp/worker_check | sed 's/[ ":,]//g;s/online//' )
worker_status1=$( grep '"online": ' /tmp/worker_check | sed 's/[ ":,]//g;s/online//' )
gpus_online=$( grep '"gpus_online":' /tmp/worker_check | sed 's/[ ":,]//g;s/gpus_online//' | bc )
gpus_online1=$( grep '"gpus_online":' /tmp/worker_check | sed 's/[ ":,]//g;s/gpus_online//' | bc )
gpus_offline=$( grep '"gpus_offline":' /tmp/worker_check | sed 's/[ ":,]//g;s/gpus_offline//' | bc )
gpus_offline1=$( grep '"gpus_offline":' /tmp/worker_check | sed 's/[ ":,]//g;s/gpus_offline//' | bc )
if [[ "$worker_status" = 'false' ]] ; then
  echo "cron script initiated due to worker being offline at `date '+%Y-%m-%d_%H:%M:%S'`" >> /home/user/worker_check.log
  sleep 180
  curl -s -w '\n%{http_code}' -H 'Content-Type: application/json' -H 'Authorization: Bearer {$apikey}' https://api2.hiveos.farm/api/v2/farms/{$farmid}/workers/{$workerid} | sed 's/^000-H//g;/^200-H/d;/^200$/d' | jq '.' > /tmp/worker_check
  if [[ "$worker_status1" = 'false' ]] ; then
    echo "cron script restarted worker due to worker being offline at `date '+%Y-%m-%d_%H:%M:%S'`" >> /home/user/worker_check.log
    sudo reboot
  fi
elif [[ "$worker_status" != 'true' ]] && [[ "$worker_status" != 'false' ]] ; then
  echo "cron script initiated at `date '+%Y-%m-%d_%H:%M:%S'` but was unable to check the online status of worker" >> /home/user/worker_check.log
fi
if [[ "$gpus_online" -lt 8 ]] && [[ "$gpus_offline" -gt 0 ]] ; then
  echo "cron script initiated due to only $gpus_online gpus being online and $gpus_offline gpus being offline at `date '+%Y-%m-%d_%H:%M:%S'`" >> /home/user/worker_check.log
  sleep 180
  curl -s -w '\n%{http_code}' -H 'Content-Type: application/json' -H 'Authorization: Bearer {$apikey}' https://api2.hiveos.farm/api/v2/farms/{$farmid}/workers/{$workerid} | sed 's/^000-H//g;/^200-H/d;/^200$/d' | jq '.' > /tmp/worker_check
  if [[ "$gpus_online1" -lt 8 ]] && [[ "$gpus_offline1" -gt 0 ]] ; then
    echo "cron script restarted worker due to only $gpus_online1 gpus being online and $gpus_offline1 gpus being offline at `date '+%Y-%m-%d_%H:%M:%S'`" >> /home/user/worker_check.log
    sudo reboot
  fi
fi
