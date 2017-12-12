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
* ~~Ensures that the source code is checked out to `/home/core` (you will be prompted for your GitHub credentials)~~
* Generates self-signed SSL certs if they are not found for the given domain
* Ensures that certificates have been imported as Kubernetes secrets
* Create several [ingress rules](ingress.yaml) to route to the various exposed services
* Starts up the Kubernetes [NGINX Ingress Controller](https://github.com/kubernetes/ingress/tree/master/controllers/nginx)
* Starts up a Pod running an instance of RabbitMQ
* Starts up a Pod running a shell containing a pre-installed [cis_interface](https://github.com/cropsinsilico/cis_interface)
* Starts up a Pod running the Cloud9 IDE

## Viewable Interfaces
The [platform ingress rules](platform/ingress.yaml) will set up routes to the following applications:
* https://cloud9.cis.ndslabs.org will be routed to `/ide.html` on Cloud9
* https://datawolf.cis.ndslabs.org will route to `/datawolf/editor` on the DataWolf demo instance
* https://noflo.cis.ndslabs.org will route to `/index.html` on the NoFlo UI demo instance
* https://prototype.cis.ndslabs.org will route to `/` on the Crops in Silico Prototype UI
* https://prototype.cis.ndslabs.org/api will route to `/api` on the Crops in Silico Prototype API server

Once all of the containers have started up, we can easily test out the dfferent proposed components to see what might fit best.

# Viewing Pod Logs
To view the logs of an individual pod (where your work items are being executed):
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
```

# Running the Framework (Coming Soon)
To run the [`cis_interface`](https://github.com/cropsinsilico/cis_interface) CLI as a Kubernetes Job:
```bash
kubectl create -f framework/hello/python.job.yaml
kubectl create -f framework/hello/gcc.job.yaml
kubectl create -f framework/hello/gpp.job.yaml
```

This will create the Job objects on your Kubernetes cluster. Job objects themselves don't execute anything (and therefore don't keep logs), but they will spawn Pods (groups of containers) to execute the desired work item(s).

## Monitoring Jobs (Coming Soon)
To view the status of your jobs and their pods:
```bash
core@my-vm ~/cis-startup $ kubectl get jobs,pods -a
NAME            DESIRED   SUCCESSFUL   AGE
jobs/gcc-test   1         1            1m

NAME                             READY     STATUS      RESTARTS   AGE
po/gcc-test-hzcq8                0/1       Completed   0          1m
```

This will list off all running jobs and their respectives pods (replicas).

NOTE: The `-a` flag tells to Kubernetes to include pods that have `Completed` in the returned list.

## Viewing Job logs
We can view the logs for our Jobs the same we that we view logs for other pods:
```bash
# View the logs of a Pod spawned by the "gcc-test" Job
kubectl logs -f gcc-test-hzcq8 
```

## Viewing output (Coming Soon)
Check the contents of your shared storage to view output files:
```bash
core@nds842-node1 ~ $ du -h -a /var/glfs/global/jobs
512	/var/glfs/global/jobs/data-cleanup/results/TEST_1_gene_expression_UNMAPPED.tsv
0	/var/glfs/global/jobs/data-cleanup/results/TEST_1_gene_expression_MAP.tsv
1.0K	/var/glfs/global/jobs/data-cleanup/results/log_gene_prioritization_pipeline.yml
5.5K	/var/glfs/global/jobs/data-cleanup/results
9.5K	/var/glfs/global/jobs/data-cleanup
512	/var/glfs/global/jobs/gene-prioritization/results/drug_A_bootstrap_net_correlation_pearson_Mon_03_Jul_2017_23_37_33.461636543_viz.tsv
512	/var/glfs/global/jobs/gene-prioritization/results/drug_B_bootstrap_net_correlation_pearson_Mon_03_Jul_2017_23_37_33.502016782_viz.tsv
512	/var/glfs/global/jobs/gene-prioritization/results/drug_C_bootstrap_net_correlation_pearson_Mon_03_Jul_2017_23_37_33.491072654_viz.tsv
512	/var/glfs/global/jobs/gene-prioritization/results/drug_E_bootstrap_net_correlation_pearson_Mon_03_Jul_2017_23_37_33.497779369_viz.tsv
512	/var/glfs/global/jobs/gene-prioritization/results/drug_D_bootstrap_net_correlation_pearson_Mon_03_Jul_2017_23_37_33.502823591_viz.tsv
512	/var/glfs/global/jobs/gene-prioritization/results/ranked_genes_per_phenotype_bootstrap_net_correlation_pearson_Mon_03_Jul_2017_23_37_33.781181335_download.tsv
512	/var/glfs/global/jobs/gene-prioritization/results/top_genes_per_phenotype_bootstrap_net_correlation_pearson_Mon_03_Jul_2017_23_37_33.786688327_download.tsv
7.5K	/var/glfs/global/jobs/gene-prioritization/results
12K	/var/glfs/global/jobs/gene-prioritization
512	/var/glfs/global/jobs/gene-set-characterization/results/net_path_ranked_by_property_Mon_03_Jul_2017_23_37_33.879306793.df
512	/var/glfs/global/jobs/gene-set-characterization/results/net_path_sorted_by_property_score_Mon_03_Jul_2017_23_37_33.885757923.df
512	/var/glfs/global/jobs/gene-set-characterization/results/net_path_droplist_Mon_03_Jul_2017_23_37_33.891902446.tsv
5.5K	/var/glfs/global/jobs/gene-set-characterization/results
2.5K	/var/glfs/global/jobs/gene-set-characterization/job-parameters.yml
12K	/var/glfs/global/jobs/gene-set-characterization
365K	/var/glfs/global/jobs/samples-clustering/results/consensus_matrix_cc_net_nmf_Mon_03_Jul_2017_23_39_04.368379831_viz.tsv
512	/var/glfs/global/jobs/samples-clustering/results/silhouette_average_cc_net_nmf_Mon_03_Jul_2017_23_39_04.496203184_viz.tsv
4.0K	/var/glfs/global/jobs/samples-clustering/results/samples_label_by_cluster_cc_net_nmf_Mon_03_Jul_2017_23_39_04.502247810_viz.tsv
1.5K	/var/glfs/global/jobs/samples-clustering/results/clustering_evaluation_result_Mon_03_Jul_2017_23_39_05.487591743.tsv
56M	/var/glfs/global/jobs/samples-clustering/results/genes_by_samples_heatmap_cc_net_nmf_Mon_03_Jul_2017_23_39_09.115032196_viz.tsv
594K	/var/glfs/global/jobs/samples-clustering/results/genes_averages_by_cluster_cc_net_nmf_Mon_03_Jul_2017_23_39_17.276435136_viz.tsv
404K	/var/glfs/global/jobs/samples-clustering/results/genes_variance_cc_net_nmf_Mon_03_Jul_2017_23_39_17.396065711_viz.tsv
305K	/var/glfs/global/jobs/samples-clustering/results/top_genes_by_cluster_cc_net_nmf_Mon_03_Jul_2017_23_39_17.440115690_download.tsv
58M	/var/glfs/global/jobs/samples-clustering/results
4.5K	/var/glfs/global/jobs/samples-clustering/job-parameters.yml
58M	/var/glfs/global/jobs/samples-clustering
58M	/var/glfs/global/jobs
```

We can see that no matter which node ran our jobs, all of our output files are available in one place.

NOTE: On multi-node clusters, you will need to SSH to a compute node or start a container mounting the shared storage. The shared storage is not currently mounted on the master.

## Cleaning Up Jobs
Kubernetes leaves it up to the user to delete their own Job objects, which stick around indefinitely to ease debugging.

To delete a job (and trigger clean up of its corresponding pods):
```bash
kubectl delete jobs/gcc-test
```

To delete all jobs:
```bash
kubectl delete jobs --all
```

NOTE: Supposedly, Kubernetes can be configured to clean up completed/failed jobs
[automatically](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#jobs-history-limits), 
but I have not yet experimented with this feature.
