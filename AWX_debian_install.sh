#! /usr/bin/env bash
########################################################################
#
# Fontys Semester3: AWX Installatie [ Josh ]
#
########################################################################

set -o pipefail

function update_debian() {


    #  Update Debian


    cmd_list="update upgrade dist-upgrade autoremove clean"

    # Run!
    for cmd in $cmd_list
    do
        apt-get -y $cmd
    done

}

function install_depend() {


    # Installeer Dependencies


    pkg_list="git git build-essential curl jq net-tools dnsutils"

    for pkg in $pkg_list
    do
        apt-get install -y $pkg
    done

}

function install_k3s() {


    # Installeer k3s
    curl -sfL https://get.k3s.io | bash -

    # Verifieer dat node is aangemaakt
    kubectl get nodes

    # Wacht tot node Ready is
    kubectl wait --for=condition=ready --timeout=45s --all nodes
}

function install_AWX_operator() {

   # Clone awx-operator
   git clone https://github.com/ansible/awx-operator.git

   # CD naar directory
   cd awx-operator/

   # Exporteer NAMESPACE
   export NAMESPACE=awx
   kubectl create ns ${NAMESPACE}
   kubectl config set-context --current --namespace=$NAMESPACE

   apt update -y

   # Selecteer laatste versie awx-operator
   #RELEASE_TAG=`curl -s https://api.github.com/repos/ansible/awx-operator/releases/latest | grep tag_name | cut -d '"' -f 4`
   RELEASE_TAG=0.17.0

   echo $RELEASE_TAG
   sleep 5

   git checkout $RELEASE_TAG

   export NAMESPACE=awx

   # Voer build command uit.
   make deploy

   # 130 seconden wachten tot pod draait
   sleep 130
   kubectl get pods

}

function install_AWX {

   # Download static-pvc.yaml voor pvc claim
   wget https://raw.githubusercontent.com/Joseph01101010/Awx-Installatie/main/static-pvc.yaml

   # Download kustomization.yaml file
   wget https://raw.githubusercontent.com/Joseph01101010/Awx-Installatie/main/kustomization.yaml

   # Creeer static-pvc
   kubectl create -f static-pvc.yaml
   sleep 5

   # Controleer dat pvc is aangemaakt
   kubectl get pvc -n awx
   sleep 10

   # Maak en Fix rechten op k3s mappen
   chmod -R 777 /var/lib/rancher/k3s/*


   # Voer kustomization.yaml uit
   kubectl apply -f kustomization.yaml

   sleep 120

   chmod -R 777 /var/lib/rancher/k3s/*
   # Check pvc
   kubectl get pvc -n awx
   sleep 3

   # Voer watch command uit om pods te volgen
   kubectl logs -f deployments/awx-operator-controller-manager -c awx-manager
   #watch kubectl get pods -l "app.kubernetes.io/managed-by=awx-operator"

}


function main() {

    update_debian
    install_depend
    install_k3s
    install_AWX_operator
    install_AWX

}

main "$@"
