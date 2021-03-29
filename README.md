# Steps to deploy kubevirt-console-gateway operator on OCP cluster (One Time Setup)

## 1- Clone kubevirt-console-operator git repository:
``` bash
$ git clone https://github.com/aadib3/kubevirt-console-operator.git
Cloning into 'kubevirt-console-operator'...
remote: Enumerating objects: 29, done.
remote: Counting objects: 100% (29/29), done.
remote: Compressing objects: 100% (18/18), done.
remote: Total 29 (delta 8), reused 29 (delta 8), pack-reused 0
Receiving objects: 100% (29/29), 11.93 KiB | 5.96 MiB/s, done.
Resolving deltas: 100% (8/8), done.
```


## 2- Set the following variables with the appropriate image locations:
$ kuberbacproxyimage=\<private-repo-name:port\>/kubebuilder/kube-rbac-proxy:v0.5.0

$ kubevirtconsoleoperatorimage=\<private-repo-name:port\>/yaacov/kubevirt-console-operator

$ kubevirtconsoleimage=\<private-repo-name:port\>/yaacov/kubevirt-console

$ kubevirtconsolewebimage=\<private-repo-name:port\>/yaacov/kubevirt-console-web-app-novnc

$ kubevirtconsoleroute=kubevirt-console.apps.ocp4.xxx.xxx


## 3- Login into OCP cluster to deploy kubevirt-console-operator:
$ oc login https://api.ocp4.xxx.xxx:6443
``` bash
Authentication required for https://api.ocp4.xxx.xxx:6443 (openshift)
Username: xxxx
Password: 
Login successful.

You have access to xx projects, the list has been suppressed. You can list all projects with ' projects'

Using project "default".
$
```


## 4- Inject the image variables into oc-gate-operator.yaml file and create oc-gate-operator objects:
$ sed "s|KUBERBCPROXYIMAGE|$kuberbacproxyimage|g;s|KUBEVIRTCONSOLEOPERATORIMAGE|$ocgateoperatorimage|g" kubevirt-console-operator-template.yaml > kubevirt-console-operator.yaml

$ oc create -f kubevirt-console-operator.yaml
``` bash
```

$ oc get all -n oc-gate-operator -l control-plane=controller-manager
``` bash
```


## 5- Inject the ocgateimage and ocgateroute variables into gateserver.yaml and create the GateServer custom resource:

$ sed "s|KUBEVIRTCONSOLEIMAGE|$kubevirtconsoleimage|g;s|KUBEVIRTCONSOLEROUTE|$kubevirtconsoleroute|g;s|KUBEVIRTCONSOLEWEBIMAGE|$kubevirtconsolewebimage|g" kubevirt-console-server-template.yaml > kubevirt-console-server.yaml

$ oc create -f kubevirt-console-server.yaml
``` bash
```

$ oc get kcs,po,deployment,svc,route -n kubevirt-console
``` bash
```
# Steps to authenticate access to a virtual machine noVNC console (Everytime console access is required)

## 1- Set the following variables required for creating the operator CRs:
``` bash
$ vm=rhel6-150.ocp4.xxx.xxx 
$ ns=ocs-cnv
$ kubevirtconsoleroute=kubevirt-console.apps.ocp4.xxx.xxx
$ consolepath=k8s/apis/subresources.kubevirt.io/v1alpha3/namespaces/$ns/virtualmachineinstances/$vm/vnc
$ posturl=https://$kubecirtconsoleroute/login.html
$ postpath=/noVNC/vnc_lite.html?path=$kubevirtconsolepath
$ date=$(date "+%y%m%d%H%M")
```

## 2- Inject the ocgatepath into gatetoken.yaml and create the GateToken custom resource:
$ sed "s|VMNAME|$vm-$date|g;s|KUBEVIRTCONSOLEPOSTPATH|$kubevirtconsolepath|g" kubevirt-console-token-template.yaml > kubevirt-console-token.yaml

$ oc create -f kubevirt-console-token.yaml
``` bash
```

$ bt=bearer token

$ apipath="https://api.ocp4.xxx.xxx:6443/apis/ocgate.yaacov.com/v1beta1/namespaces/oc-gate/gatetokens"

$ data=\'{\"apiVersion\":\"gateway.yaacov.com/v1beta1\",\"kind\":\"KubevirtConsoleToken\",\"metadata\":{\"name\":\"$vm-$date\",\"namespace\":\"kubevirt-console\"},\"spec\":{\"match-path\":\"^/$consolepath\"}}\'

$ curl -k -H 'Accept: application/json' -H \"Authorization: Bearer $bt\" -H \"Content-Type: application/json\" --request POST --data $data $apipath

## 3- Set and display the content of consoleurl:
$ token=$(oc describe gatetoken $vm-$date -n oc-gate | grep Token: | awk '{print $2}')

$ consoleurl=${posturl}?token=${token}\\&then=$postpath

$ echo $consoleurl
``` bash
```
![Screenshot from 2021-03-15 18-26-52](https://user-images.githubusercontent.com/77073889/111229439-47ce9980-85bc-11eb-9cb7-d0b6119c2497.png)

$ curl -k -H \'Accept: application/json\' -H \"Authorization: Bearer $bt\" $apipath/$vm-$date \| jq .status.token
