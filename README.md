# cis-startup
An experiment in running the Crops in Silico platform, framework, and IDE under [Kubernetes](https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/).

# Prerequisites
* Docker 1.13.0+
* Mount propagation must be enabled
  * See https://docs.portworx.com/knowledgebase/shared-mount-propogation.html#ubuntu-configuration-and-shared-mounts

NOTE: On an Ubuntu AWS VM, I had to run the following command (or else the kubelet would fail to start):
```bash
sudo mount --make-shared /
```

# Clone the Source
```bash
git clone https://github.com/bodom015/cis-startup
cd cis-startup
```

# Building all Docker Images
To quickly build up all of the pipeline images:
```bash
./compose.sh build
```

NOTE: If your Docker version differs, you may need to adjust the version in `./compose.sh`

To push all images to DockerHub (required for multi-node cluster):
```bash
./compose.sh push
```

NOTE: You will need to `docker login` (and probably change the image/tags in the `docker-compose.yml`) before you can push

# Running Hyperkube
Before continuing, ensure that you have [enabled shared mount propagation](https://docs.portworx.com/knowledgebase/shared-mount-propogation.html#ubuntu-configuration-and-shared-mounts) on your VM.

To run a development Kubernetes cluster (via Docker):
```bash
./kube.sh
```

NOTE: You'll need to manually add the path the the `kubectl` binary to your `$PATH`.

## New to Kubernetes?
For some introductory slides to Kubernetes terminology, check out https://docs.google.com/presentation/d/1VDYrSlwLY_Efucq_n75m9Rf_euJIOIACh27BfOmh-ps/edit?usp=sharing

# Running the Platform
To run the Crops in Silico platform and a Cloud9 IDE:
```bash
./cis.sh
```

## Behind the Scenes
The `./cis.sh` helper script does several things:
* Ensures that the user has a `basic-auth` secret set up for Cloud9 to consume
* Generates self-signed SSL certs if they are not found for the given domain
* Ensures that certificates have been imported as Kubernetes secrets
* Create several [ingress rules](ingress.yaml) to route to the various exposed services
* Starts up the Kubernetes [NGINX Ingress Controller](https://github.com/kubernetes/ingress/tree/master/controllers/nginx)
* Starts up a Pod running an instance of RabbitMQ
* Starts up a Pod running the Cloud9 IDE
* Starts up a Pod running the CiS prototype UI / API
* Starts up a Pod running the NoFlo UI (for consideration)
* Starts up a Pod running the DataWolf Editor (for consideration)
* You should now be able to run some [example Jobs](framework/hello/) using the [cis_interface](https://github.com/cropsinsilico/cis_interface) [Docker container](framework/Dockerfile)

## Viewable Interfaces
The [platform ingress rules](platform/ingress.yaml) will set up routes to the following applications:
* https://cloud9.cis.ndslabs.org will be routed to `/ide.html` on Cloud9
* https://datawolf.cis.ndslabs.org will route to `/datawolf/editor` on the DataWolf demo instance
* https://noflo.cis.ndslabs.org will route to `/index.html` on the NoFlo UI demo instance
* https://prototype.cis.ndslabs.org will route to `/` on the Crops in Silico Prototype UI
* https://prototype.cis.ndslabs.org/api will route to `/api` on the Crops in Silico Prototype API server

Once all of the containers have started up, we can easily test out the dfferent proposed components to see what might fit best.

# Viewing Pod Logs
Every component of the platform runs in a separate container.

To view the logs of an individual pod (or container):
```bash
core@my_vm01 ~/cis-startup $ kubectl get pods
NAME                             READY     STATUS    RESTARTS   AGE
cis-datawolf-1947004756-4rpwz    1/1       Running   1          23h
cis-prototype-1660495536-35dbz   2/2       Running   1          8h
cloud9-4228688985-nmhrh          1/1       Running   1          23h
default-http-backend-q727m       1/1       Running   1          23h
nginx-ilb-rc-1sqck               1/1       Running   1          23h
noflo-ui-898494385-k9npn         1/1       Running   1          23h
rabbitmq-1016789879-zxzmk        1/1       Running   1          23h

# View the logs of a single-container Pod
kubectl logs -f nginx-ilb-rc-1sqck 

# For multi-container pods, you must specify a container with -c
kubectl logs -f cis-prototype-1660495536-35dbz -c cis-api
kubectl logs -f cis-prototype-1660495536-35dbz -c cis-ui
```

# Running the Framework
To run the [`cis_interface`](https://github.com/cropsinsilico/cis_interface) CLI as a Kubernetes Job:
```bash
kubectl create -f framework/hello/hello-py.job.yaml
kubectl create -f framework/hello/hello-c.job.yaml
kubectl create -f framework/hello/hello-cpp.job.yaml
```

This will create the Job objects on your Kubernetes cluster. Job objects themselves don't execute anything (and therefore don't keep logs), but they will spawn Pods (groups of containers) to execute the desired work item(s).

## Monitoring Jobs
To view the status of your jobs and their pods:
```bash
core@my_vm01 ~/cis-startup/framework $ kubectl get jobs
NAME      DESIRED   SUCCESSFUL   AGE
hello-c   1         0            2s

core@my_vm01 ~/cis-startup/framework $ kubectl get pods -a
NAME                             READY     STATUS    RESTARTS   AGE
hello-c-7twxg                    1/1       Running   0          6s
```

This will list off all running jobs and their respectives pods (replicas).

NOTE: The `-a` flag tells to Kubernetes to include pods that have `Completed` in the returned list.

## Viewing Job logs
We can view the logs for our Jobs the same we that we view logs for other pods:
```bash
core@my_vm01 ~/cis-startup/framework $ kubectl logs -f hello-c-8xlpt
Hello from C
hello(C): Created I/O channels
hello(C): Received 14 bytes from file: this is a test
hello(C): Sent to outq
hello(C): Received 14 bytes from queue: this is a test
hello(C): Sent to outf
Goodbye from C
```

## Viewing output (Coming Soon)
The current examples produce no output, so this pattern is still under development.

## Cleaning Up Jobs
Kubernetes leaves it up to the user to delete their own Job objects, which stick around indefinitely to ease debugging.

To delete a job (and trigger clean up of its corresponding pods):
```bash
kubectl delete job hello-c
```

To delete all jobs:
```bash
kubectl delete jobs --all
```

NOTE: Supposedly, Kubernetes can be configured to clean up completed/failed jobs
[automatically](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#jobs-history-limits), 
but I have not yet experimented with this feature.
