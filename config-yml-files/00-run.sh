
###########################################################################################################
# run from the console through this command `sh ./00-run.sh`
###########################################################################################################

# create a GCE persistent disk
gcloud compute disks create --size=110GB --zone=us-east1-b gce-nfs-disk

# create a GKE cluster
# gcloud container clusters create mappedinn-cluster --machine-type=g1-small --num-nodes=1
gcloud container clusters create mappedinn-cluster --num-nodes=1

# changing the context of kubectl
gcloud container clusters get-credentials mappedinn-cluster --zone us-east1-b --project mappedinn
## but it seems to be not necessary since after creating the cluster the context has been automatically changed

kubectl create -f 01-dep-nfs.yml # have a look on https://kubernetes.io/docs/concepts/storage/volumes/#gcepersistentdisk
kubectl create -f 02-srv-nfs.yml
kubectl create -f 03-pv-and-pvc-nfs.yml
kubectl create -f 04-dep-busybox.yml

# check if things are correctly working
kubectl exec nfs-busybox-2762569073-b2m99  -- cat /mnt/index.html

# clean up the cluster (don't forget the clean up the cluster to not get charged)
kubectl delete deployment nfs-busybox nfs-server
kubectl delete service nfs-server
kubectl delete pvc nfs
kubectl delete pv nfs

## delete the cluser
gcloud container clusters delete mappedinn-cluster

## deleting the GCE PV
gcloud compute disks delete gce-nfs-disk
