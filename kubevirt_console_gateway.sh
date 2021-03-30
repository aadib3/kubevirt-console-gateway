#!/bin/bash

usage(){
if [ "$#" -lt 1 -o "$#" -gt 2 ]; then echo "usage: $0 <action: build|destroy|gettoken> <vmname>"; exit 1; fi
if [ "$1" = "build" ]; then clonerepo; createoperator; sleep 10; createserver; fi
if [ "$1" = "destroy" ]; then clonerepo; deletegateserver; deleteoperator; cleanup; fi
if [ "$1" = "gettoken" ]; then
  if [ -n "$2" ]; then vm=$2; else vm=rhel6-150.ocp4.goldman.lab; fi
  clonerepo; getbt; creategatetoken; sleep; displayconsoleurl
fi
}

clonerepo(){
git clone $gitrepo
cd $reponame
}

createoperator(){
sed "s|KUBERBCPROXYIMAGE|$kuberbacproxyimage|g;s|KUBEVIRTCONSOLEOPERATORIMAGE|$kubevirtconsoleoperatorimage|g" $reponame-operator-template.yaml > $reponame-operator.yaml
oc create -f $reponame-operator.yaml
oc get all -n $reponame-operator
}

createserver(){
sed "s|KUBEVIRTCONSOLEIMAGE|$kubevirtconsoleimage|g;s|KUBEVIRTCONSOLEROUTE|$kubevirtconsoleroute|g;s|KUBEVIRTCONSOLEWEBIMAGE|$kubevirtconsolewebimage|g" $reponame-server-template.yaml > $reponame-server.yaml
diff $reponame-server-template.yaml $reponame-server.yaml
oc create -f $reponame-server.yaml
}

deletegateserver(){
sed "s|KUBEVIRTCONSOLEIMAGE|$kubevirtconsoleimage|g;s|KUBEVIRTCONSOLEROUTE|$kubevirtconsoleroute|g;s|KUBEVIRTCONSOLEWEBIMAGE|$kubevirtconsolewebimage|g" $reponame-server-template.yaml > $reponame-server.yaml
oc delete -f $reponame-server.yaml
}

deleteoperator(){
sed "s|KUBERBCPROXYIMAGE|$kuberbacproxyimage|g;s|KUBEVIRTCONSOLEOPERATORIMAGE|$kubevirtconsoleoperatorimage|g" $reponame-operator-template.yaml > $reponame-operator.yaml
oc delete -f $reponame-operator.yaml
}

cleanup(){
cd $HOME/console-access/$reponame
if [ $? -eq 0 ]; then rm -rf $reponame; fi
}

getbt(){
sasecret=$(oc describe sa vx-sa -n $reponame| grep "^Tokens" | awk '{print $2}')
bt=$(oc describe secret $sasecret -n $reponame | grep "^token" | awk '{print $2}')
}

creategatetoken(){
consolepath=k8s/apis/subresources.kubevirt.io/v1alpha3/namespaces/$ns/virtualmachineinstances/$vm/vnc
postpath=/noVNC/vnc_lite.html?path=$consolepath
sed "s|VMNAME|$vm-$date|g;s|CONSOLEPATH|$consolepath|g" $reponame-token-template.yaml > $reponame-token.yaml
oc create -f $reponame-token.yaml
#data=\'{\"apiVersion\":\"$apiversion\",\"kind\":\"GateToken\",\"metadata\":{\"name\":\"$vm-$date\",\"namespace\":\"oc-gate\"},\"spec\":{\"match-path\":\"^/$consolepath\"}}\'
#echo
#echo Curl Command: curl -k -H \'Accept: application/json\' -H \"Authorization: Bearer $bt\" -H \"Content-Type: application/json\" --request POST --data $data $apipath
#echo; echo
#echo $data
#eval curl -k -H \'Accept: application/json\' -H \"Authorization: Bearer $bt\" -H \"Content-Type: application/json\" --request POST --data $data $apipath 2>/dev/null
}

displayconsoleurl(){
token=$(oc get kct $vm-$date -n $reponame -o json | jq .status.token | tr -d '"')
#token=$(eval curl -k -H \'Accept: application/json\' -H \"Authorization: Bearer $bt\" $apipath/$vm-$date \| jq .status.token | tr -d '"' 2>/dev/null)
consoleurl=${posturl}?token=${token}\&then=$postpath
echo $consoleurl
#echo
#echo Curl Command: curl -k -H \'Accept: application/json\' -H \"Authorization: Bearer $bt\" $apipath/$vm-$date \| jq .status.token
}

#Main
reponame=$(basename $0 | sed "s:.sh::g;s:_:-:g")
gitrepo="https://github.com/aadib3/$reponame.git"
kuberbacproxyimage=pool6-infra1.practice.redhat.com:9446/kubebuilder/kube-rbac-proxy:v0.5.0
kubevirtconsoleoperatorimage=pool6-infra1.practice.redhat.com:9446/yaacov/$reponame-operator:latest
kubevirtconsoleimage=pool6-infra1.practice.redhat.com:9446/yaacov/$reponame-server:latest
kubevirtconsolewebimage=pool6-infra1.practice.redhat.com:9446/yaacov/$reponame-web-app-novnc:latest
kubevirtconsoleroute=$reponame.apps.ocp4.goldman.lab
ns=ocs-cnv
apiversion="ocgate.yaacov.com/v1beta1"
apipath="https://api.ocp4.goldman.lab:6443/apis/$apiversion/namespaces/oc-gate/gatetokens"
date=$(date "+%y%m%d%H%M")
posturl=https://$kubevirtconsoleroute/login.html
usage $@
