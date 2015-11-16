#!/bin/bash
exec 1<>/var/log/keepalived/notify.log
exec 2<>/var/log/keepalived/notify.log

TYPE=$1
NAME=$2
STATE=$3

log() { echo -e "$(date) :: $1" ; }

log "Entering $STATE state!"

echo "$STATE" > /var/log/keepalived/cluster_requested_state

case $STATE in
  "MASTER")
    log "Begin MASTER Transition"
    rbd snap create nfs --snap $(date +%s)
    count=0
    rbd lock add nfs $(hostname -s)
    status=$?
    until [ "$status" -eq 0 ]; do
      let count=count+1
      if [ "$count" -gt 10 ]; then
        log "Timeout waiting for lock."
        exit 1
      fi
      sleep 1
      rbd lock add nfs $(hostname -s)
      status=$?
    done
    if [ "$status" -eq 0 ]; then
      /usr/bin/rbd map nfs
      /usr/bin/mount /dev/rbd/rbd/nfs /exports/nfs
      /usr/bin/systemctl start nfs-server
      if [ "$?" -eq 0 ]; then
        echo "$STATE" > /var/log/keepalived/cluster_actual_state
        log "MASTER Transition Complete"
        exit 0
      else
        echo "ERROR" > /var/log/keepalived/cluster_actual_state
        log "ERROR Transitioning to MASTER"
        exit 1
      fi
    else
      exit $status
    fi
    ;;
  *)
    log "Begin BACKUP Transition :: State $STATE"
    /usr/bin/systemctl stop nfs-server
    /usr/bin/umount /exports/nfs
    /usr/bin/rbd lock remove nfs $(hostname -s) $(rbd lock list nfs | tail -1 | awk '{ print $1 }')
    /usr/bin/rbd unmap /dev/rbd/rbd/nfs
    echo "$STATE" > /var/log/keepalived/cluster_actual_state
    log "BACKUP Transition Complete"
    exit 0
    ;;
esac
