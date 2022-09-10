namespace = spark-playground
service_account_name = spark
image_tag = v3.3.0

init:
	minikube start --cpus 4 --memory 8192
	kubectl create namespace $(namespace)
	kubectl config set-context --current --namespace=$(namespace)
	#docker exec minikube docker pull apache/spark:v3.3.0
	docker-image-tool.sh -m -r apache/spark -t v3.3.0 -f $SPARK_HOME/kubernetes/dockerfiles/spark/Dockerfile.java17 build
	kubectl proxy

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
		--conf spark.kubernetes.driver.volumes.persistentVolumeClaim.data-pvc.options.claimName=spark-data-pvc \
		--conf spark.kubernetes.driver.volumes.persistentVolumeClaim.data-pvc.mount.path=/data-volume \
		--conf spark.kubernetes.driver.volumes.persistentVolumeClaim.data-pvc.mount.path=/data-volume \
		--conf spark.kubernetes.driver.volumes.persistentVolumeClaim.data-pvc.mount.readOnly=false \
		--conf spark.kubernetes.executor.volumes.persistentVolumeClaim.data-pvc.options.claimName=spark-data-pvc \
		--conf spark.kubernetes.executor.volumes.persistentVolumeClaim.data-pvc.mount.path=/data-volume \
		--conf spark.kubernetes.executor.volumes.persistentVolumeClaim.data-pvc.mount.readOnly=false \
		--conf spark.kubernetes.container.image=apache/spark:$(image_tag) \
		--conf spark.kubernetes.container.image.pullPolicy=IfNotPresent \
		--conf spark.kubernetes.namespace=$(namespace) \
		--conf spark.kubernetes.authenticate.driver.serviceAccountName=$(service_account_name) \
		--conf spark.eventLog.enabled=True \
		--conf spark.eventLog.dir=file:///data-volume \
		local:///opt/spark/examples/jars/spark-examples_2.12-3.3.0.jar 1000
#		${SPARK_HOME}/examples/jars/spark-examples_2.12-3.3.0.jar 10

#		--conf spark.kubernetes.file.upload.path=file:///opt/spark/work-dir \

# helm

enable-spark-ui:
	google-chrome http://localhost:9912/
	kubectl port-forward svc/spark-playground-master-svc 9912:80
