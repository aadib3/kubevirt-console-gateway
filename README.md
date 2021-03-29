# Steps to deploy oc-gate operator on OCP cluster (One Time Setup)

## 1- Clone oc-gate-operator git repository:
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

$ sed "s|OCGATEIMAGE|$ocgateimage|g;s|OCGATEROUTE|$ocgateroute|g;s|OCGATEWEBIMAGE|$ocgatewebimage|g" kubevirt-console-server-template.yaml > kubevirt-console-server.yaml

$ oc create -f kubevirt-console-server.yaml
``` bash
```

$ oc get kcs,po,deployment,svc,route -n kubevirt-console
``` bash
```
