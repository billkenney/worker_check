#!/bin/bash

echo 'this script will create a service that will run every 7 minutes to check if your mining program(s) is missing any gpus or if any gpus have a hashrate of 0, and it will also check the hiveos api to check if your worker is online, that all of your gpus are online, or if there are any problems such as missed_unit, missed_hashrate, or no_hashrate. if any of these problems are present and persist for more than 3-5 minutes (depending on the problem), the service will reboot the rig.'
echo 'you will first need to complete the following steps in order to run this script:
1. Login to hiveos.farm (on a browser), click on your username in the top right corner, scroll down, and click on "Generate new Personal API-token." Once its generated, click on "Show" and copy the 220 character API key and save it somewhere.
2. Go to hiveos.farm and click on your farm, then copy and save your farm id from the url. Select each worker from the drop down list, then copy and save your worker id from the url. The format is:
https://the.hiveos.farm/farms/{$farmid}/workers/{$workerid}/
You can test whether the api is working with one or both of the following command in Terminal (replace {$apikey} and {$farmid} and/or {$workerid} with that of your own api key, farm id, and/or worker id):
curl -s -w '"'"'\\n%{http_code}'"'"' -H '"'"'Content-Type: application/json'"'"' -H '"'"'Authorization: Bearer {$apikey}'"'"' https://api2.hiveos.farm/api/v2/farms/{$farmid}
curl -s -w '"'"'\\n%{http_code}'"'"' -H '"'"'Content-Type: application/json'"'"' -H '"'"'Authorization: Bearer {$apikey}'"'"' https://api2.hiveos.farm/api/v2/farms/{$farmid}/workers/{$workerid}'
echo '-------------------------
--------------------------------------------------
---------------------------------------------------------------------------'
read -p 'do you have your api key, farm id, and worker id (y/n)? ' apicheck
if [[ "$apicheck" =~ [Yy] ]] ; then
  mkdir -p /home/user/scripts
  cd /home/user/scripts
  echo '#!/bin/bash' > /home/user/scripts/worker_check.sh

  read -p 'are you using teamredminer (y/n)? ' trmcheck
  if [[ "$trmcheck" =~ [Yy] ]] ; then
    wget https://raw.githubusercontent.com/billkenney/worker_check/main/trm_check
    cat /home/user/scripts/worker_check.sh /home/user/scripts/trm_check > /tmp/wc
    mv /tmp/wc /home/user/scripts/worker_check.sh
    rm /home/user/scripts/trm_check
    read -p 'how many teamredminer gpus are you mining with (e.g., 1, 2, 8, etc)? ' trmgpus
    sed -i "s/{trmgpus}/$trmgpus/g" /home/user/scripts/worker_check.sh
  fi

  read -p 'are you using lolminer (y/n)? ' lolcheck
  if [[ "$lolcheck" =~ [Yy] ]] ; then
    wget https://raw.githubusercontent.com/billkenney/worker_check/main/lol_check
    cat /home/user/scripts/worker_check.sh lol_check > /tmp/wc
    mv /tmp/wc /home/user/scripts/worker_check.sh
    rm /home/user/scripts/lol_check
    read -p 'how many lolminer gpus are you mining with (e.g., 1, 2, 8, etc)? ' lolgpus
    sed -i "s/{lolgpus}/$lolgpus/g" /home/user/scripts/worker_check.sh
  fi

  wget https://raw.githubusercontent.com/billkenney/worker_check/main/worker_check
  cat /home/user/scripts/worker_check.sh worker_check > /tmp/wc
  mv /tmp/wc /home/user/scripts/worker_check.sh
  rm /home/user/scripts/worker_check

  read -p 'what is your hiveos api key? ' apikey
  sed -i "s/{apikey}/$apikey/g" /home/user/scripts/worker_check.sh

  read -p 'what is your hiveos farm id? ' farmid
  sed -i "s/{farmid}/$farmid/g" /home/user/scripts/worker_check.sh

  read -p 'what is your hiveos worker id? ' workerid
  sed -i "s/{workerid}/$workerid/g" /home/user/scripts/worker_check.sh

  read -p 'are you using ifttt for notifications (y/n)? ' iftttcheck
  if [[ "$iftttcheck" =~ [Yy] ]] ; then
    read -p 'what is your ifttt api key? ' iftttkey
    read -p 'what is the name of your mining rig (e.g., worker1, worker2, etc): ' rigname
    sed -i "s/{iftttkey}/$iftttkey/g;s/{rigname}/$rigname/g" /home/user/scripts/worker_check.sh
    sed -Ei 's/# (curl -X POST -H.*ifttt)/\1/' /home/user/scripts/worker_check.sh
  fi

  apikeycheck=$( echo "$apikey" | sed 's/[\.a-zA-Z]//g' | sed -E 's/^([0-9][0-9][0-9][0-9][0-9]).*$/\1/' | bc )
  farmidcheck=$( echo "$farmid" | bc )
  workeridcheck=$( echo "$workerid" | bc )
  if [[ "$apikeycheck" -gt 0 ]] && [[ "$farmidcheck" -gt 0 ]] && [[ "$workeridcheck" -gt 0 ]] ; then
    wget https://raw.githubusercontent.com/billkenney/worker_check/main/worker_check.service
    wget https://raw.githubusercontent.com/billkenney/worker_check/main/worker_check.timer
    sudo chown root:root worker_check.service worker_check.timer
    sudo mv worker_check.service worker_check.timer /etc/systemd/system
    sudo systemctl daemon-reload
    sudo systemctl enable worker_check.timer
  elif [[ "$apikeycheck" -eq 0 ]] ; then
    echo 'please run the script again and input a valid api key...'
    exit
  elif [[ "$farmidcheck" -eq 0 ]] ; then
    echo 'please run the script again and input a valid farm id...'
    exit
  elif [[ "$workeridcheck" -eq 0 ]] ; then
    echo 'please run the script again and input a valid worker id...'
    exit
  fi

  chmod +x /home/user/scripts/worker_check.sh
  touch /home/user/worker_check.log
  chown user:user /home/user/scripts/worker_check.sh /home/user/scripts/wc.sh /home/user/worker_check.log
elif [[ "$apicheck" =~ [Nn] ]] ; then
  echo 'please generate and save your api key, farm id(s), and worker id(s) and run this script again...'
else
  echo 'invalid response, please run this script again and enter y/n at the prompt...'
fi
