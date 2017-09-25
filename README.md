# ndslabs-knoweng
An experiment in running KnowEnG pipelines as Kubernetes Jobs

# Prerequisites
* Docker (preferrably 1.10.x - 1.13.x)
* Mount propagation must be enabled
** See https://docs.portworx.com/knowledgebase/shared-mount-propogation.html#ubuntu-configuration-and-shared-mounts

NOTE: On my Ubuntu AWS VM, I had to run the following command (or else `./kube.sh` would fail to start):
```bash
sudo mount --make-shared /
```

# Clone the Source
```bash
git clone https://github.com/nds-org/ndslabs-knoweng
cd ndslabs-knoweng
```

# Building all Docker Images
To quickly build up all of the pipeline images:
```bash
./compose.sh
```

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


# Running the Platform
To run the KnowEnG platform and a Cloud9 IDE:
```bash
kubectl create -f platform/
```

For an example of the running platform, see: [knoweng.org/analyze](knoweng.org/analyze)

# Running Pipelines
To run the Data Cleanup pipeline:
```bash
kubectl create -f pipelines/dc.job.yaml
```

To run the Gene Prioritization pipeline:
```bash
kubectl create -f pipelines/gp.job.yaml
```

To run the Gene Set Characterization pipeline:
```bash
kubectl create -f pipelines/gsc.job.yaml
```

To run the Samples Clustering pipeline:
```bash
kubectl create -f pipelines/sc.job.yaml
```

This will create the Job objects on your Kubernetes cluster. Job objects themselves don't execute anything (and therefore don't keep logs),
but they will spawn Pods (groups of containers) to execute the desired work item(s).

## Monitoring Jobs
To view the status of your jobs and their pods:
```bash
core@nds842-master1 ~/ndslabs-knoweng $ kubectl get jobs,pods -a
NAME           DESIRED   SUCCESSFUL   AGE
jobs/gp-test   1         1            1m

NAME                            READY     STATUS      RESTARTS   AGE
po/gp-test-hzcq8                0/1       Completed   0          1m
```

This will list off all running jobs and their respectives pods (replicas).

NOTE: The `-a` flag tells to Kubernetes to include pods that have `Completed` in the returned list.

## Viewing Logs
To view the logs of an individual pod (where your work items are being executed):
```bash
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

# Cleaning Up Jobs
Kubernetes leaves it up to the user to delete their own Job objects, which stick around indefinitely to ease debugging.

To delete a job (and trigger clean up of its corresponding pods):
```bash
kubectl delete jobs/gp-test
```

To delete all jobs:
```bash
kubectl delete jobs --all
```
