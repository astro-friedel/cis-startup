# cis-startup
An experiment in running the Crops in Silico platform, pipelines, and IDE under [Kubernetes](https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/).

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
* Ensures that the source code is checked out to `/home/core` (you will be prompted for your BitBucket credentials)
* Generates self-signed SSL certs if they are not found for the given domain
* Ensures that certificates have been imported as Kubernetes secrets
* Create [ingress rules](ingress.yaml) to route `/ide.html` to Cloud9, and `/` to the Crops in Silico Dashboard
* Starts up the Kubernetes [NGINX Ingress Controller](https://github.com/kubernetes/ingress/tree/master/controllers/nginx)
* Starts up a Pod running an instance of RabbitMQ
* Starts up a Pod running a shell containing a pre-installed [cis_interface](https://github.com/cropsinsilico/cis_interface)
* Starts up a Pod running the Cloud9 IDE

# Viewing Pod Logs
To view the logs of an individual pod (where your work items are being executed):
```bash
root@my-vm:/home/core/cis-startup # kubectl get pods                                                                                                     
NAME                         READY     STATUS    RESTARTS   AGE
cloud9-984f9                 1/1       Running   0          4h
default-http-backend-blrqv   1/1       Running   0          4h
nest-1442377537-3hhbf        4/4       Running   0          4h
nginx-ilb-rc-02fzw           1/1       Running   0          4h

# View the logs of a single-container Pod
kubectl logs -f nginx-ilb-rc-02fzw

# For multi-container pods, you must specify a container with -c
kubectl logs -f nest-1442377537-3hhbf -c flask
```

# Running the Framework
To run the Data Cleanup pipeline:
```bash
kubectl create -f framework/hello/python.job.yaml
kubectl create -f framework/hello/gcc.job.yaml
kubectl create -f framework/hello/gpp.job.yaml
```

This will create the Job objects on your Kubernetes cluster. Job objects themselves don't execute anything (and therefore don't keep logs), but they will spawn Pods (groups of containers) to execute the desired work item(s).

## Monitoring Jobs
To view the status of your jobs and their pods:
```bash
core@my-vm ~/cis-startup $ kubectl get jobs,pods -a
NAME           DESIRED   SUCCESSFUL   AGE
jobs/gp-test   1         1            1m

NAME                            READY     STATUS      RESTARTS   AGE
po/gp-test-hzcq8                0/1       Completed   0          1m
```

This will list off all running jobs and their respectives pods (replicas).

NOTE: The `-a` flag tells to Kubernetes to include pods that have `Completed` in the returned list.

## Viewing Pod logs
Use the pod name to check the log output:
```bash
# View the logs of a Pod spawned by a Job
kubectl logs -f gp-test-hzcq8 
```

## Viewing output files
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
kubectl delete jobs/gp-test
```

To delete all jobs:
```bash
kubectl delete jobs --all
```

NOTE: Supposedly, Kubernetes can be configured to clean up completed/failed jobs
[automatically](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#jobs-history-limits), 
but I have not yet experimented with this feature.
