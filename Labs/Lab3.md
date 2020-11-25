# Lab 3 - Integrating Shift Left + WAAP
Written by Michael Braun<br>

The purpose of this lab is to build on the infrastructure built in Lab 2. We will look to integrate Shift Left into the CI/CD pipeline and install WAAP with Helm.


## Setup

In order to run this lab, please ensure you have:<br><br>
<b> Accounts: </b><br>
[Github Account](https://github.com)<br>
[Dockerhub Account](https://dockerhub.com) <br>
[Azure Account](https://portal.azure.com) with App Registration that has "Contributor" permission<br>
[Check Point CSPM Account](https://secure.dome9.com/) - API key<br>
[Check Point Infinity Portal](https://portal.checkpoint.com) - Token for WAAP<br>
<b>Tools:</b><br>
AZ CLI<br>
Git<br>
Docker<br>
Kubectl<br>
Helm<br>
<br>

## Part 1 - Integrating Shift Left into CI/CD pipeline

First, navigate to the Check Point CSPM and select the "Shift Left". Walk through the selection, in "OS Selection" select Linux and in "Download" download the "X64 for Linux" version. You do not need to go through the rest of the steps as there is no configuration. Save the binary to the root of our project. We are now ready to integrate Shift Left into the CI/CD pipeline. <br><br>

First, we must add to the Environment variables:

```
      CHKP_CLOUDGUARD_ID: ${{ secrets.CHKP_CLOUDGUARD_ID }}
      CHKP_CLOUDGUARD_SECRET: ${{ secrets.CHKP_CLOUDGUARD_SECRET }}
```

Open up the pipeline.yml file and insert the following code after the "Checkout Code" step:

```  
    - name: ShiftLeft Web Application Code Scan
      run: |
            chmod +x ./shiftleft
            ./shiftleft code-scan -s .
      continue-on-error: true
```

I have included the "continue-on-error" flag so that the pipeline will still complete. In a production pipeline, you would not want to do this. 

Let's now add the container scan functionality:

```
    - name: Shift Left Container Scan
      run: |
        docker save <docker_hub_user>/badwebapp -o badwebapp.tar
        ./shiftleft image-scan -t 1800 -i ./badwebapp.tar
      continue-on-error: true

```

Commit the changes and navigate to the "Actions" tab. Open up the pipeline and expand the new sections we added. You should see the results of the two scans that we added.

## Part 2 - Adding WAAP to the Kubernetes Cluster

Clone the cpWaapJuice Repository. Located [HERE](https://github.com/metalstormbass/cpWaapJuice). <br>

In order to add WAAP to the Kubernetes Cluster, we need to change the way traffic reaches the web app. Instead of using the service type Load Balancer, we are going to use an ingress controller. First we need to update the app.yml file. Open it up and make it look like the following:

```
apiVersion: v1
kind: Service
metadata:
  namespace: <NAMESPACE>
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
  type: ClusterIP
```

Notice that the "type" is now ClusterIP. We then need to delete the deployment and redeploy it.

```
kubectl delete -f app.yml
kubectl apply -f app.yml
```

Now if you examine the cluster, and you will see that there is no longer an external IP address. We will use the Helm chart to deploy the ingress controller and the WAAP agent. Change over to the cpWaapJuice repository. Let's start by building the Helm chart. Do this by running:

```
helm package .
```

This command packages the helm chart. Next, we can deploy it:

```
helm install cpwaap CheckPoint-WAAP-0.1.5.tgz --namespace=<NAMESPACE_NAME> --set mysvcname=vwa-service --set mysvcport=80 --set nanoToken=<CPNANO_TOKEN> --set appURL=<NAMESPACE_NAME>.<LOCATION_OF_RESOURCEGROUP>.cloudapp.azure.com
```

Browse to the URL which has been defined in the step above and you should see our web app. In the [Infinity Next Portal](httpS://portal.checkpoint.com), you can plug in that URL into the "Assets" page. Once you have configured the asset, click on "Enforce" <br><br>

Once the enforcement is completed, then navigate to http://<NAMESPACE_NAME>.<LOCATION_OF_RESOURCEGROUP>.cloudapp.azure.com/test<br>

Enter the following into the field:

```
' or 1=1;--
```

<b>This completes Lab 3</b>

## Cleanup

To delete the deployment in Azure, run the following commands:

```
az login 
az aks delete --name <k8_CLUSTERNAME> --resource-group <RESOURCE_GROUP_NAME> -y
az group delete -n <RESOURCE_GROUP_NAME> -y
```



