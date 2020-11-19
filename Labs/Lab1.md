# Lab 1 - Git, Docker and CI/CD
Written by Michael Braun

The purpose of this lab is to learn how to use Git, Docker and build a simple CI/CD pipeline.

## Setup

In order to run the labs, please ensure you have:<br><br>

Github Account<br>
Dockerhub Account<br>
Azure Account<br>
<br>
AZ CLI<br>
Kubectl<br>
Docker<br>
<br>

I've include configure.sh that installs the tools on linux.


## Part 1

First, let's create a new repository on Github. It can be a public repository as there is nothing confidential. Once is it created, run the following command:

```
git clone <your_repository_url>
```

Next, download the source code for the python web application. Located HERE. Copy the extracted files into the git repository that you created. The file structure should look like:

```
<your_repo>
    