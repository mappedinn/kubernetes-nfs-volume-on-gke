# Create kubernetes NFS volume on Google Container Engine (GKE)

## TL;DR
Have a look directly on [./config-yml-files/00-run.sh](./config-yml-files/00-run.sh)

## 0. Version of kubernetes on GKE cluster

    # Make sure to have kubernetes with that version else errors related to DNS will occur
    kubectl version
    # Client Version: version.Info{Major:"1", Minor:"8", GitVersion:"v1.8.6", GitCommit:"6260bb08c46c31eea6cb538b34a9ceb3e406689c", GitTreeState:"clean", BuildDate:"2017-12-21T06:34:11Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"linux/amd64"}
    # Server Version: version.Info{Major:"1", Minor:"8+", GitVersion:"v1.8.6-gke.0", GitCommit:"ee9a97661f14ee0b1ca31d6edd30480c89347c79", GitTreeState:"clean", BuildDate:"2018-01-05T03:36:42Z", GoVersion:"go1.8.3b4", Compiler:"gc", Platform:"linux/amd64"}
    ## PS: by default, the kubectl on GKE is 1.7.11-gke.1
    ## So, upgrade the GKE cluster to v1.8.6-gke.0
    ## 1. Create a GKE cluster and GCE persistent disk

## 1. Create a GKE cluster and GCE persistent disk

    # create a GCE persistent disk
    gcloud compute disks create --size=10GB --zone=us-east1-b gce-nfs-disk

    # create a GKE cluster
    ## I am assume that you already run this command `gcloud init`
    ## there is no need for `gcloud config set compute/zone us-east1-b` if it is already done.
    gcloud container clusters create mappedinn-cluster --num-nodes=1 --zone us-east1-b

## 2. Configure the context for the kubectl

    gcloud container clusters get-credentials mappedinn-cluster --zone us-east1-b --project amine-testing


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

    # you have to get the id of the pod to make the check (you will have to identify the name of the pod)
    kubectl exec nfs-busybox-2762569073-b2m99  -- cat /mnt/index.html

## 8. Clean up

    # clean up the cluster (don't forget the clean up the cluster to not get charged)
    kubectl delete deployment nfs-busybox
    kubectl delete service nfs-server
    kubectl delete deployment nfs-server
    kubectl delete pvc nfs
    kubectl delete pv nfs

    ## delete the cluser
    gcloud container clusters delete mappedinn-cluster --zone us-east1-b

    ## deleting the GCE PV
    gcloud compute disks delete gce-nfs-disk --zone us-east1-b
