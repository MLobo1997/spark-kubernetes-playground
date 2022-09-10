namespace = default
service_account_name = spark
image_tag = sparkpi

init:
	minikube start --cpus 4 --memory 8192
	#kubectl create namespace $(namespace)
	#kubectl config set-context --current --namespace=$(namespace)

create-service-account:
	kubectl create serviceaccount spark
	kubectl create clusterrolebinding spark-role --clusterrole=edit --serviceaccount=$(namespace):$(service_account_name) --namespace=$(namespace)

enable-nfs:
	helm repo add stable https://charts.helm.sh/stable
	helm install nfs stable/nfs-server-provisioner \
	  --set persistence.enabled=true,persistence.size=5Gi
	sleep 5
	kubectl apply -f spark-pvc.yml


sparkpi:
	spark-submit \
		--master k8s://http://127.0.0.1:8001 \
		--deploy-mode cluster \
		--class org.apache.spark.examples.SparkPi \
		--conf spark.executor.instances=3 \
		--conf spark.executor.memory=1g \
		--conf spark.executor.cores=1 \
		--conf spark.kubernetes.container.image=spark:$(image_tag) \
		--conf spark.kubernetes.container.image.pullPolicy=Never \
		--conf spark.kubernetes.namespace=$(namespace) \
		--conf spark.kubernetes.authenticate.driver.serviceAccountName=$(service_account_name) \
		--conf spark.eventLog.enabled=True \
		local:///opt/spark/examples/jars/spark-examples_2.12-3.2.1.jar 1000

# helm

install-spark-helm-chart:
	helm repo add bitnami https://charts.bitnami.com/bitnami
	docker exec minikube docker pull docker.io/bitnami/spark:3.3.0-debian-11-r16
	helm install -f values.yaml spark-playground bitnami/spark --version 6.3.1

enable-spark-ui:
	google-chrome http://localhost:9912/
	kubectl port-forward svc/spark-playground-master-svc 9912:80

sparkpi-spark-playground:
	 spark-submit \
		--class org.apache.spark.examples.SparkPi \
		--conf spark.kubernetes.container.image=bitnami/spark:3.3.0-debian-11-r16 \
		--master k8s://https://127.0.0.1:8001 \
		--conf spark.kubernetes.driverEnv.SPARK_MASTER_URL=spark://spark-playground-master-svc:7077 \
		--conf spark.kubernetes.file.upload.path=""\
		--deploy-mode cluster \
		/home/miguel.lobo/.sdkman/candidates/spark/3.3.0-local/examples/jars/spark-examples_2.12-3.3.0.jar 1000

