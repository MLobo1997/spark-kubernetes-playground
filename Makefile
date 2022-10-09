namespace = spark-playground
service_account_name = spark
spark_version=3.3.0
image_tag = v$(spark_version)
host_volume_path = /shared
logs_dir = logs
data_dir = data
mount_path = /spark-volume
localstack_compose_file = localstack-compose.yml
jars_bucket = spark-jars
logs_bucket = spark-logs
minikube_internal_host = 192.168.59.1
minikube_internal_host_and_port = "$(minikube_internal_host)/24"

init:
	minikube start --driver virtualbox --host-only-cidr $(minikube_internal_host_and_port) --cpus 4 --memory 8192
	kubectl create namespace $(namespace)
	kubectl config set-context --current --namespace=$(namespace)
	docker-image-tool.sh -m -r ourapache -t $(image_tag) -f ${SPARK_HOME}/kubernetes/dockerfiles/spark/Dockerfile.java17 build
	kubectl create serviceaccount spark
	kubectl create clusterrolebinding spark-role --clusterrole=edit --serviceaccount=$(namespace):$(service_account_name) --namespace=$(namespace)
	kubectl proxy

enable-localstack:
	docker-compose -f $(localstack_compose_file) up

create-buckets:
	awslocal s3api create-bucket --bucket $(jars_bucket)
	awslocal s3api create-bucket --bucket $(logs_bucket)

simple-sparkpi:
	spark-submit \
		--master k8s://http://127.0.0.1:8001 \
		--deploy-mode cluster \
		--class org.apache.spark.examples.SparkPi \
		--packages org.apache.hadoop:hadoop-aws:3.3.4,com.amazonaws:aws-java-sdk-s3:1.12.262,com.amazonaws:aws-java-sdk:1.12.262,com.amazonaws:aws-java-sdk-core:1.12.262 \
        --conf spark.hadoop.fs.s3a.endpoint=http://$(minikube_internal_host):4566 \
        --conf spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem \
        --conf spark.hadoop.fs.s3a.fast.upload=true \
        --conf spark.hadoop.fs.s3a.access.key=foobar \
        --conf spark.hadoop.fs.s3a.secret.key=foobar \
        --conf spark.driver.extraJavaOptions="-Divy.cache.dir=/tmp -Divy.home=/tmp" \
		--conf spark.executor.instances=3 \
		--conf spark.executor.memory=1g \
		--conf spark.executor.cores=1 \
        --conf spark.kubernetes.file.upload.path=s3a://$(jars_bucket)/ \
		--conf spark.kubernetes.container.image=ourapache/spark:$(image_tag) \
		--conf spark.kubernetes.container.image.pullPolicy=Never \
		--conf spark.kubernetes.namespace=$(namespace) \
		--conf spark.kubernetes.authenticate.driver.serviceAccountName=$(service_account_name) \
		--conf spark.eventLog.enabled=True \
		--conf spark.eventLog.dir=s3a://$(logs_bucket)/test \
		file://${SPARK_HOME}/examples/jars/spark-examples_2.12-$(spark_version).jar 10


stop:
	minikube delete
	docker-compose -f $(localstack_compose_file) down
	#sudo ufw enable


#TODO list
# 1. move jars inside docker image to avoid download time
