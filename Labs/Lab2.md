# Lab 2 - Kubernetes, CI/CD & Helm/Log.IC
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


