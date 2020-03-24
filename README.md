# What is Merlin adding to this project?

We want to have a containerized `kubectl` port forwarding, so that we can access remote micro-services inside
GKE without exposing public IPs. The Kubernetes port forwarding doesn't work alone inside a Docker container,
we need to add another proxy for the connection to be accessible to sibling containers. Inside your
`docker-compose.yaml`, add the following service:

```yaml
<service_name>:
  build:
    context: github.com/merlinapp/gcloud-kubectl-helm.git#master
  volumes:
    - type: bind
      source: ./<directory_to_google_service_account_file>
      target: /keys
      read_only: true
  expose:
    - <port_to_expose>
  networks:
    - merlin_net
  entrypoint:
    - sh
    - -c
    - |
      gcloud auth activate-service-account --key-file=/keys/<google_service_account_filename>
      gcloud container clusters get-credentials <cluster> --project <project> --zone <zone>
      /proxy.sh <port_to_expose> <kubectl_forwarded_port> # These ports must be different. You can pick a random kubectl port number.
      kubectl --namespace <namespace> port-forward service/<service> <kubectl_forwarded_port>:<micro-service_port>
```

The original documentation of this repository can be found below.

# gcloud-kubectl-helm
Docker image for the quaternity of [gcloud](https://cloud.google.com/sdk/docs/), [helm](https://www.helm.sh), [kubectl](https://kubernetes.io/docs/reference/kubectl/kubectl/) and [SOPS](https://github.com/mozilla/sops).

The image also contains:
* [cloud_sql_proxy](https://github.com/GoogleCloudPlatform/cloudsql-proxy)
* [gnupg](https://pkgs.alpinelinux.org/package/edge/main/x86_64/gnupg)
* [kubeval](https://github.com/instrumenta/kubeval)
* [mysql-client](https://pkgs.alpinelinux.org/package/edge/main/x86_64/mysql-client)
* [yq](https://github.com/mikefarah/yq)

[![Docker Pulls](https://img.shields.io/docker/pulls/kiwigrid/gcloud-kubectl-helm.svg?style=plastic)](https://hub.docker.com/r/kiwigrid/gcloud-kubectl-helm/)
[![CircleCI](https://img.shields.io/circleci/project/github/kiwigrid/gcloud-kubectl-helm/master.svg?style=plastic)](https://circleci.com/gh/kiwigrid/gcloud-kubectl-helm)

- `latest` latest build from master
- `tag` Images will be taged by combination of packed HELM client version, gcloud and build-number, e.g. 2.12.1-228.0.0-68. There will be no git tag anymore. View all available image tags on [DockerHub](https://hub.docker.com/r/kiwigrid/gcloud-kubectl-helm/tags)

# Adding changes to this repo
* Use a fork of this repo
* Add a PR

# Usage

## With CGP Service Account and key file

Passing script with multiple commands
```bash
docker run -v /path/to/your/script.sh:/data/commands.sh:ro kiwigrid/gcloud-kubectl-helm
```

Passing script and GCP key-file
```bash
docker run -v /path/to/your/script.sh:/data/commands.sh:ro -volume /path/to/your/key-file.json:/data/gcp-key-file.json:ro kiwigrid/gcloud-kubectl-helm
```

## Interactive usage with your personal GCP Account

```bash
docker run -ti -v /path/to/your/workspace:/data/ kiwigrid/gcloud-kubectl-helm bash
# authenticate and paste token
$ gcloud auth application-default login

# setup kubectl context
$ gcloud container clusters get-credentials

# run helm
$ helm install release /data/your/chart -f values.yaml
# or with sops encrypted secrets file
$ helm secrets install release /data/your/chart -f values.yaml -f secrets.myapp.yaml
```

## CI/CD context
Using this image from a CI/CD pipeline is very handy.
It's recommended to start the container at the beginning of your pipeline.
Afterwards one can pass single commands to running container.

```bash
CONTAINER_NAME=gkh-container
# Start container
docker run \
  --volume /path/to/your/workdir:/workspace:ro \
  --workdir /workspace
  --volume /path/to/your/gcp-key-file.json:/data/gcp-key-file.json:ro \
  --env GOOGLE_APPLICATION_CREDENTIALS=/data/gcp-key-file.json
  --rm \
  -t \
  --name $CONTAINER_NAME \
  kiwigrid/gcloud-kubectl-helm:latest /bin/bash

# Execute arbitrary commands
docker exec $CONTAINER_NAME gcloud auth activate-service-account --key-file=/data/gcp-key-file.json
docker exec $CONTAINER_NAME gcloud config set project my-gcp-project-id
docker exec $CONTAINER_NAME gcloud container clusters get-credentials my-gke-cluster --project my-gcp-project-id --zone my-gke-zone

docker exec $CONTAINER_NAME helm list
docker exec $CONTAINER_NAME gcloud deployment-manager deployments describe my-deployment

# Kill
docker kill $CONTAINER_NAME
```

## Command file examples

Authorize access to GCP with a service account and fetch credentials for running cluster
```bash
gcloud auth activate-service-account --key-file=/data/gcp-key-file.json
gcloud container clusters get-credentials <clusterName> --project <projectId> [--region=<region> | --zone=<zone>]

helm list
kubectl get pods --all-namespaces
```

## Import GPG Keys

To import public GPG keys from keyserver, add them space separated to GPG_PUB_KEYS env variable.

```bash
docker run -e GPG_PUB_KEYS=<key id>   kiwigrid/gcloud-kubectl-helm:latest
```

## Add distributed Helm Chart Repositories

To include adding of distributed helm chart repos, add REPO_YAML_URL as env variable.
E.g.

```bash
docker run -e REPO_YAML_URL=https://raw.githubusercontent.com/helm/hub/master/config/repo-values.yaml kiwigrid/gcloud-kubectl-helm:latest
```

# Credits
This repo is inspired by
* https://github.com/eversC/gcloud-k8s-helm
* https://github.com/lfaoro/gcloud-kubectl-helm
