#!/bin/sh

########################################################
function waitPodDown()
{
  echo "Waiting for server down."
  echo ""
  retry=0
  maxRetry=$1
  interval=$2
  sts=0
  while [ $retry -lt $maxRetry ] && [ $sts -eq 0 ]
  do
     echo "Retry= $retry"
     echo "# kubectl get pods -n sample-domain1-ns -l weblogic.domainUID=domain1-uid -o wide"
     res=$(kubectl get pods -n sample-domain1-ns -l weblogic.domainUID=domain1-uid -o wide)
     echo "$res"
     if [ "$res" = "" ]
     then
        sts=1;
        echo "All pods are down!"
        break;
     fi
     let retry++
     echo "Sleep $interval seconds. "
     echo " "
     sleep $interval
  done
}
#########################################################

waitPodDown 20 30;

