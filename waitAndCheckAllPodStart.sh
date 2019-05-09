#!/bin/sh

########################################################
function waitPodStart()
{
  echo "Waiting for server pods to start."
  echo " "
  retry=0
  maxRetry=$1
  interval=$2
  serverReplica=2
  sts=0
  while [ $retry -lt $maxRetry ] && [ $sts -eq 0 ]
  do
     echo "Retry= $retry"
     echo "# kubectl get pods -n sample-domain1-ns -l weblogic.domainUID=domain1-uid -o wide"
     res=$(kubectl get pods -n sample-domain1-ns -l weblogic.domainUID=domain1-uid -o wide)
     echo "$res"
     echo " "
     
     mgServerNum=0
     for((i=1;i<=serverReplica;i++));
     do
          mgServerName="domain1-uid-managed-server$i";
          if [[ $res =~ $mgServerName ]] 
          then
          	let mgServerNum++
          fi
     done

     if [[ $res =~ "domain1-uid-admin-server" ]] && [ $mgServerNum -eq $serverReplica ] && [[ ! $res =~ "0/1" ]] && [[ ! $res =~ "Terminating" ]];
     then
        sts=1;
        echo "All servers are running."
        break;
     fi
     let retry++
     echo "Sleep $interval seconds."
     echo " "
     sleep $interval
  done
}
#########################################################


waitPodStart 20 30;

