# Spark cluster in Kubernetes Playground

A setup to locally test Apache Spark applications in a Kubernetes (K8S) cluster backed by a S3-based Hadoop.

This repo is a WIP.

## Components

This setup has the following components:

* A [Docker image](docker-image) with a Spark-hadoop setup.
  * Created a lightweight image by doing several build stages and copying only the necessary files.
* The Kubernetes cluster is based in [Minikube](https://github.com/kubernetes/minikube) and runs in Virtualbox (check the [Makefile](Makefile)).
* The S3 buckets are emulated by [Localstack](https://github.com/localstack/localstack) and initialized in [this docker-compose](docker-compose.yml).
* To monitor the Spark Applications, you can start a Spark History Server by applying [this K8S manifest](history-server.yaml).
