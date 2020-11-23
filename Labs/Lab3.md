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
        docker save michaelbraunbass/badwebapp -o badwebapp.tar
        ./shiftleft image-scan -t 1800 -i ./badwebapp.tar
      continue-on-error: true

```