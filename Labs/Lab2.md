# Lab 2 - Kubernetes, CI/CD & Helm/CSPM
Written by Michael Braun

The purpose of this lab is to develop a basic understanding of Kubernetes & Helm. Also, we will add Kubernetes to the CI/CD pipeline created in Lab 1.


## Setup

In order to run this lab:, please ensure you have:<br><br>

[Github Account](https://github.com)<br>
[Dockerhub Account](https://dockerhub.com) <br>
[Azure Account](https://portal.azure.com) with App Registration that has "Contributor" permission<br>
<br>
AZ CLI<br>
Docker<br>
Kubectl<br>
Helm<br>
<br>

This can all be done on either Windows or Linux. Either way, please make sure you have all the tools defined above. I've include configure.sh that installs all the tools on linux in the resources folder.

<b> This lab uses the pipeline built in Lab 1 </b>

## Part 1 - Creating and Authenticating to the AKS Cluster

For this lab, we will be using the Azure command line utility (az).<br>

First, lets start by authenticating to Azure

```
az login
```

Next, create a Resource Group to in which to build the AKS cluster. 

```
az group create -n <NAME_OF_RESOURCEGROUP> -l <AZURE_LOCATION>
```

Create the AKS cluster. 

```
az aks create --name <CLUSTER_NAME> --resource-group <NAME_OF_RESOURCEGROUP> --node-count 3 
``` 
This step will take some time. Go grab a cup of coffee...<br><br>

Log into the Azure console and examine what has been created. Notice there is an additional resource group that contains all of the components of a Kubernetes cluster.

Once complete, we can authenticate to the cluster. 

```
az aks get-credentials --name <CLUSTER_NAME> --resource-group <NAME_OF_RESOURCEGROUP>
```

That's it! You have created a managed Kubernetes cluster. You can now start running kubectl commands against it.<br>

Let's start with:

```
kubectl get all
```

Then:

```
kubectl get namespaces
```

and:

```
kubectl get all -n kube-system
```

These are all the components of a managed Kubernetes cluster from Azure.


## Part 2 - Creating a Kubernetes deployment

We are now going to create a deployment on the Kubernetes cluster.<br>

First, make a namespace for all of the resources to live in.

```
kubectl create namespace <NAMESPACE_NAME>
```

Next, create a file in the root of the directory, called app.yml. This is where we will define the configuration for our web application. <br>

First, we will start with the deployment peice. Note the container name from the previous lab. Also note the container port: 8080. As mentioned in the lecture, labels are used for matching services to deployments. I recommend typing this all out so that you look closely at all resources.

```
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: <NAMESPACE_NAME>
  name: <DEPLOYMENT_NAME>
  labels:
    app: vwa
    tier: frontend
spec:
  selector: 
    matchLabels:
      app: vwa
      tier: frontend
  strategy: 
    type: Recreate
  template:
    metadata:
      labels: 
        app: vwa
        tier: frontend
    spec:
      containers:
      - image:  <docker_image_from_dockerhub>
        name: vwa
        ports:
        - containerPort: 8080
          name: vwa
```

Let's apply this:

```
kubectl apply -f app.yml -n <NAMESPACE_NAME>
```

Then:

```
kubectl get all -n <NAMESPACE_NAME>
```
You should now see the resource created by the app.yml file. Let's dig into the deployment a little bit more. Examine the pod further:

```
kubectl describe pod <POD_NAME> -n <NAMESPACE_NAME>
```

To be able to access this resource from the internet we need to expose this with a service. Edit the app.yml file and add the following:

```
---
apiVersion: v1
kind: Service
metadata:
  namespace: <NAMESPACE_NAME>
  name: vwa-service
  labels:
    app: vwa
spec: 
  ports:
   - port: 80
     targetPort: 8080
  selector:
    app: vwa
    tier: frontend
  type: LoadBalancer
  ```
  
This creates the service. As explained in the lecture, this will spin up an Azure loadbalancer. Notice that the labels match the deployment. Also, that the service is listening on port 80 send the traffic to port 8080. Explore what was just created:

```
kubectl get all -n <NAMESPACE_NAME>
```

Under "Service", you should see an external IP Address. If the load balancer has not finished provisioning, it will be in a "PENDING" state. You will have to wait until fully provisioned to see the load balancer. Browse to the IP address and you should be able to see the web application from Lab 1.

## 