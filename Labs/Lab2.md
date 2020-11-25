# Lab 2 - Kubernetes, CI/CD & Helm/CSPM
Written by Michael Braun

The purpose of this lab is to develop a basic understanding of Kubernetes & Helm. Also, we will add Kubernetes to the CI/CD pipeline created in Lab 1.


## Setup

In order to run this lab, please ensure you have:<br><br>
<b> Accounts: </b><br>
[Github Account](https://github.com)<br>
[Dockerhub Account](https://dockerhub.com) <br>
[Azure Account](https://portal.azure.com) with App Registration that has "Contributor" permission<br>
[Check Point CSPM Account](https://secure.dome9.com/) <br><br>
<b>Tools:</b><br>
AZ CLI<br>
Git<br>
Docker<br>
Kubectl<br>
Helm<br>
<br>

This can all be done on either Windows or Linux. Either way, please make sure you have all the tools defined above. I've include configure.sh that installs all the tools on linux in the resources folder.

<b> This lab uses the pipeline built in Lab 1. Start in the root of the same working directory specified in Lab 1. </b>

## Part 1 - Creating and Authenticating to the AKS Cluster

For this lab, we will be using the Azure command line utility (az).<br>

First, lets start by authenticating to Azure

```
az login
```

Next, create a Resource Group to in which to build the AKS cluster. 

```
az group create -n <NAME_OF_RESOURCEGROUP> -l <AZURE_LOCATION->
```

Create the AKS cluster. 

```
az aks create --name <CLUSTER_NAME> --resource-group <NAME_OF_RESOURCEGROUP> --node-count 3 --generate-ssh-keys
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

First, make a namespace for all of the resources to live in. <b> Make sure that you keep it lower case and no symbols. This is required for a step in the next lab </b>

```
kubectl create namespace <NAMESPACE_NAME>
```

Next, create a file in the root of the directory, called <b>app.yml</b>. This is where we will define the configuration for our web application. <br>

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
  replicas: 4 
  strategy:
      type: RollingUpdate
      rollingUpdate:
         maxUnavailable: 25%
         maxSurge: 1
  template:
    metadata:
      labels: 
        app: vwa
        tier: frontend
    spec:
      containers:
      - image:  <dockerhubusername>/badwebapp:latest
        imagePullPolicy: Always
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

To be able to access this resource from the internet we need to expose this with a service. Edit the <b>app.yml</b> file and add the following:

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

## Part 3 -Testing Continuous Deployment

First, it's important to understand that Kubernetes is not "watching" the container repository to see if there is a new image available. Our cluster is set to always pull new images when a pod is created. To set up a no downtime deployment, we need to trick the cluster into thinking that it needs to rebuild the pods. <br><br>

To get started, add the Microsoft Azure app registration credentials to the repository secrets. Then, define environment variables. Also, for consistency, let's include the Azure Resource Group Name (Created in Part 2). Finally, make sure that you include the name of the Kubernetes deployment (as defined in app.yml), namespace and K8 Cluster Name(Created in Part 2). Edit <b>pipeline.yml</b>
```
jobs:
  Pipeline-Job:
    name: 'My First Pipeline Job'
    runs-on: ubuntu-latest
    env:
      AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      AZURE_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
      AZ_RG: ${{ secrets.AZ_RG }} #Azure Resource Group Name
      K8_CLUSTERNAME: ${{ secrets.K8_CLUSTERNAME }}
      K8_DEPLOYMENT: ${{ secrets.K8_DEPLOYMENT }}
      K8_NAMESPACE: ${{ secrets.K8_NAMESPACE }}
```

Once the Variables have been defined, we must configure the pipeline to authenticate to Azure & the Kubernetes cluster.

```
    - name: Update K8 Cluster
      run: |
         az login  --service-principal -u ${AZURE_CLIENT_ID} -p ${AZURE_CLIENT_SECRET} -t ${AZURE_TENANT_ID}
         az aks get-credentials --name ${K8_CLUSTERNAME} --resource-group ${AZ_RG}
```

Next, we need to append a unique value as a label. As explained above, the reasoning for this is to have the Kubernetes cluster rebuild the pods. To generate a unique value, we will use the RANDOM command.


```
         num=$[ ( $RANDOM % 100 )  + 1 ]
         kubectl patch deployment ${K8_DEPLOYMENT} -n $K8_NAMESPACE -p "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"date\":\"${num}\"}}}}}"
```

The final <b>pipeline.yml</b> file should look like this:
```
name: "My First Pipeline"

on:
  push:
    branches:
    - main

jobs:
  Pipeline-Job:
    name: 'My First Pipeline Job'
    runs-on: ubuntu-latest
    env:
      AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      AZURE_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
      AZ_RG: ${{ secrets.AZ_RG }}
      K8_CLUSTERNAME: ${{ secrets.K8_CLUSTERNAME }}
      K8_DEPLOYMENT: ${{ secrets.K8_DEPLOYMENT }}
      K8_NAMESPACE: ${{ secrets.K8_NAMESPACE }}
      CHKP_CLOUDGUARD_ID: ${{ secrets.CHKP_CLOUDGUARD_ID }}
      CHKP_CLOUDGUARD_SECRET: ${{ secrets.CHKP_CLOUDGUARD_SECRET }}
    
    steps:
    - name: Checkout Code
      uses: actions/checkout@v1
      
    - name: Build Docker Container
      run: |
         sudo docker build . -t <dockerhub_username>/badwebapp
         
    - name: Smoke Test
      run: |
         sudo docker run -d -p 8080:8080 <dockerhub_username>/badwebapp
         sleep 4
         curl localhost:8080
       
    - name: Set up QEMU
      uses: docker/setup-qemu-action@v1
      
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v1
             
    - name: Login to DockerHub
      uses: docker/login-action@v1 
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}

    - name: Build and push
      id: docker_build
      uses: docker/build-push-action@v2
      with:
        push: true
        tags: <dockerhub_username>/testbadapp:latest
        
    - name: Update K8 Cluster
      run: |
         az login  --service-principal -u ${AZURE_CLIENT_ID} -p ${AZURE_CLIENT_SECRET} -t ${AZURE_TENANT_ID}
         az aks get-credentials --name ${K8_CLUSTERNAME} --resource-group ${AZ_RG}
         num=$[ ( $RANDOM % 100 )  + 1 ]
         kubectl patch deployment ${K8_DEPLOYMENT} -n $K8_NAMESPACE -p "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"date\":\"${num}\"}}}}}"
```

Once this is complete, please edit the HTML code in the web application and commit the changes. You should see that after the pipeline is finished running, that the web application has updated. It may take some time. Monitor the progress with the kubectl command. Make another change to the HTML and commit again. <br>

<b> You now have a fully functional CI/CD pipeline! </b>

## Part 4 - Using Helm to onboard to Check Point CSPM

Now that we have our Kubernetes cluster working as it should, let's connect it to Check Point CSPM to get some visibility. Navigate to the CSPM Dashboard and run through the onboarding steps for a Kubernetes cluster. This process uses Helm to install the Check Point agents on the Kubernetes cluster. Once onboarded, you can run compliance policies, and even view Log.IC (if you have access to it)

<br><br>
<b> This concludes Lab 2!</b>

## Cleanup

<b> NOTE: DO NOT RUN THESE COMMANDS IF YOU PLAN TO DO LAB 3</b><br>

To delete the deployment in Azure, run the following commands:

```
az aks delete --name <k8_CLUSTERNAME> --resource-group <RESOURCE_GROUP_NAME> -y
az group delete -n <RESOURCE_GROUP_NAME> -y
```
