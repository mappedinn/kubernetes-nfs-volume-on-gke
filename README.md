# Create kubernetes NFS volume on Google Container Engine (GKE)

## TL;DR
Have a look directly on [./config-yml-files/00-run.sh](./config-yml-files/00-run.sh)

## 1. Create a GKE cluster and GCE persistent disk

    # create a GCE persistent disk
    gcloud compute disks create --size=110GB --zone=us-east1-b gce-nfs-disk

    # create a GKE cluster
    ## I am assume that you already run this command `gcloud init`
    ## there is no need for `gcloud config set compute/zone us-east1-b` if it is already done.
    gcloud container clusters create mappedinn-cluster

## 2. Configure the context for the kubectl

    gcloud container clusters get-credentials mappedinn-cluster --zone us-east1-b --project mappedinn


## 3. Create an NFS server with its PersistentVolumeClaim (PVC)

    # Create a Deployment for the NFS server
    kubectl create -f 02-dep-nfs.yml

## 4. Create a service for the NFS server to expose it

    # Expose the NFS server
    kubectl create -f 03-srv-nfs.yml

## 5. Create NFS volume

    # Creation of NFS volume (PV and PVC)
    kubectl create -f 03-pv-and-pvc-nfs.yml

## 6. Create a Deployment of busybox for checking the NFS volume

    # create a Deployment of busybox
    kubectl create -f 04-dep-busybox.yml

## 7. Check

    # you have to get the id of the pod to make the check
    kubectl exec nfs-busybox-2762569073-b2m99  -- cat /mnt/index.html
