
###########################################################################################################
# run from the console through this command `sh ./00-run.sh`
###########################################################################################################

# Make sure to have kubernetes with that version else errors related to DNS will occur
kubectl version
# Client Version: version.Info{Major:"1", Minor:"8", GitVersion:"v1.8.6", GitCommit:"6260bb08c46c31eea6cb538b34a9ceb3e406689c", GitTreeState:"clean", BuildDate:"2017-12-21T06:34:11Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"linux/amd64"}
# Server Version: version.Info{Major:"1", Minor:"8+", GitVersion:"v1.8.6-gke.0", GitCommit:"ee9a97661f14ee0b1ca31d6edd30480c89347c79", GitTreeState:"clean", BuildDate:"2018-01-05T03:36:42Z", GoVersion:"go1.8.3b4", Compiler:"gc", Platform:"linux/amd64"}
## PS: by default, the kubectl on GKE is 1.7.11-gke.1
## So, upgrade the GKE cluster to v1.8.6-gke.0

# create a GCE persistent disk
gcloud compute disks create --size=10GB --zone=us-east1-b gce-nfs-disk

# create a GKE cluster
# gcloud container clusters create mappedinn-cluster --machine-type=g1-small --num-nodes=1
gcloud container clusters create mappedinn-cluster --num-nodes=1 --zone us-east1-b

# changing the context of kubectl
gcloud container clusters get-credentials mappedinn-cluster --zone us-east1-b --project amine-testing
## but it seems to be not necessary since after creating the cluster the context has been automatically changed

kubectl create -f 01-dep-nfs.yml # have a look on https://kubernetes.io/docs/concepts/storage/volumes/#gcepersistentdisk
kubectl create -f 02-srv-nfs.yml
kubectl create -f 03-pv-and-pvc-nfs.yml
kubectl create -f 04-dep-busybox.yml

# check if things are correctly workiang
kubectl exec nfs-busybox-2762569073-b2m99  -- cat /mnt/index.html

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
