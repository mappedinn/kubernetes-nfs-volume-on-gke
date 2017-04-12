# Example on how to create kubernetes NFS volume on Google Container Engine (GKE)

## 1. Create a GKE cluster and GCE persistent disk

    # create a GCE persistent disk
    gcloud compute disks create --size=2GB --zone=us-east1-b gce-nfs-disk

    # create a GKE cluster
    ## I am assume that you already run this command `gcloud init`
    ## there is no need for `gcloud config set compute/zone us-east1-b` if it is already done.
    gcloud container clusters create mappedinn-cluster

## 2. Config the context for the kubectl

    gcloud container clusters get-credentials mappedinn-cluster --zone us-east1-b --project mappedinn

## 3. Creation of the PersistentVolume (PV) and the PersistentVolumeClaim (PVC)

    # Create a PV based on the GCE persistent disk & claim it by PVC
    kubectl create -f 01-pv-gce.yml

## 4. Creation of an NFS server

    # Create a Deployment for the NFS server
    kubectl create -f 02-dep-nfs.yml

## 5. Create a service for the NFS server to expose it

    # Expose the NFS server
    kubectl create -f 03-srv-nfs.yml

After exposing the NFS server, the IP address have to be obained through the command below to create a NFS volume:

    $ kubectl get services
    NAME         CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
    kubernetes   10.247.240.1     <none>        443/TCP                      23m
    nfs-server   10.247.250.208   <none>        2049/TCP,20048/TCP,111/TCP   2m

The IP address of the service is `10.247.250.208`. This IP address is used to configurate the file `04-pv-and-pvc-nfs.yml`.   

## 6. Creation of NFS volume

    # Creation of NFS volume (PV and PVC)
    kubectl create -f 04-pv-and-pvc-nfs.yml

## 7. Create a Deployment of busybox for checking the NFS volume

    # create a Deployment of busybox
    kubectl create -f 05-dep-busybox.yml

## Acutal issue

The Deployment `busybox` did not work since it was not able to get access to the NFS volume as it can be seen on the `kubectl describe pods`:

    $ kubectl describe pods  nfs-busybox-2762569073-lhb5p
    Name:		nfs-busybox-2762569073-lhb5p
    Namespace:	default
    Node:		gke-mappedinn-cluster-default-pool-f94cb0d4-fmfb/10.240.0.3
    Start Time:	Wed, 12 Apr 2017 04:12:20 +0400
    Labels:		name=nfs-busybox
    		pod-template-hash=2762569073
    Annotations:	kubernetes.io/created-by={"kind":"SerializedReference","apiVersion":"v1","reference":{"kind":"ReplicaSet","namespace":"default","name":"nfs-busybox-2762569073","uid":"b1e523ae-1f14-11e7-a084-42010a8e0...
    		kubernetes.io/limit-ranger=LimitRanger plugin set: cpu request for container busybox
    Status:		Pending
    IP:		
    Controllers:	ReplicaSet/nfs-busybox-2762569073
    Containers:
      busybox:
        Container ID:
        Image:		busybox
        Image ID:		
        Port:		
        Command:
          sh
          -c
          while true; do date > /mnt/index.html; hostname >> /mnt/index.html; sleep $(($RANDOM % 5 + 5)); done
        State:		Waiting
          Reason:		ContainerCreating
        Ready:		False
        Restart Count:	0
        Requests:
          cpu:		100m
        Environment:	<none>
        Mounts:
          /mnt from my-pvc-nfs (rw)
          /var/run/secrets/kubernetes.io/serviceaccount from default-token-20n4b (ro)
    Conditions:
      Type		Status
      Initialized 	True
      Ready 	False
      PodScheduled 	True
    Volumes:
      my-pvc-nfs:
        Type:	PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
        ClaimName:	nfs
        ReadOnly:	false
      default-token-20n4b:
        Type:	Secret (a volume populated by a Secret)
        SecretName:	default-token-20n4b
        Optional:	false
    QoS Class:	Burstable
    Node-Selectors:	<none>
    Tolerations:	<none>
    Events:
      FirstSeen	LastSeen	Count	From								SubObjectPath	Type		Reason		Message
      ---------	--------	-----	----								-------------	--------	------		-------
      5m		5m		1	default-scheduler								Normal		Scheduled	Successfully assigned nfs-busybox-2762569073-lhb5p to gke-mappedinn-cluster-default-pool-f94cb0d4-fmfb
      3m		48s		2	kubelet, gke-mappedinn-cluster-default-pool-f94cb0d4-fmfb			Warning		FailedMount	Unable to mount volumes for pod "nfs-busybox-2762569073-lhb5p_default(b1e7c901-1f14-11e7-a084-42010a8e0116)": timeout expired waiting for volumes to attach/mount for pod "default"/"nfs-busybox-2762569073-lhb5p". list of unattached/unmounted volumes=[my-pvc-nfs]
      3m		48s		2	kubelet, gke-mappedinn-cluster-default-pool-f94cb0d4-fmfb			Warning		FailedSync	Error syncing pod, skipping: timeout expired waiting for volumes to attach/mount for pod "default"/"nfs-busybox-2762569073-lhb5p". list of unattached/unmounted volumes=[my-pvc-nfs]
      37s		37s		1	kubelet, gke-mappedinn-cluster-default-pool-f94cb0d4-fmfb			Warning		FailedMount	MountVolume.SetUp failed for volume "kubernetes.io/nfs/b1e7c901-1f14-11e7-a084-42010a8e0116-nfs" (spec.Name: "nfs") pod "b1e7c901-1f14-11e7-a084-42010a8e0116" (UID: "b1e7c901-1f14-11e7-a084-42010a8e0116") with: mount failed: exit status 32
    Mounting command: /home/kubernetes/bin/mounter
    Mounting arguments: 10.247.250.208:/exports /var/lib/kubelet/pods/b1e7c901-1f14-11e7-a084-42010a8e0116/volumes/kubernetes.io~nfs/nfs nfs []
    Output: Running mount using a rkt fly container
    run: group "rkt" not found, will use default gid when rendering images
    mount.nfs: Connection timed out    


In the dashboard, the error is as follows:

**Unable to mount volumes for pod "nfs-busybox-2762569073-lhb5p_default(b1e7c901-1f14-11e7-a084-42010a8e0116)": timeout expired waiting for volumes to attach/mount for pod "default"/"nfs-busybox-2762569073-lhb5p". list of unattached/unmounted volumes=[my-pvc-nfs]**

**Error syncing pod, skipping: timeout expired waiting for volumes to attach/mount for pod "default"/"nfs-busybox-2762569073-lhb5p". list of unattached/unmounted volumes=[my-pvc-nfs]**    
