# Lab 1 - Git, Docker, and CI/CD
Written by Michael Braun

The purpose of this lab is to learn how to use Git, Docker and build a simple CI/CD pipeline.

## Setup

In order to run the labs, please ensure you have:<br><br>

[Github Account](https://github.com)<br>
[Dockerhub Account](https://dockerhub.com) <br>
[Azure Account](https://portal.azure.com) with App Registration that has "Contributor" permission (for later lab)<br>
<br>
AZ CLI<br>
Docker<br>
Kubectl(for later lab)<br>
Helm(for later lab)<br>
<br>

This can all be done on either Windows or Linux. Either way, please make sure you have all the tools defined above. I've include configure.sh that installs the tools on linux.


## Part 1 - Web Application

First, let's create a new repository on Github. It can be a public repository as there is nothing confidential. At this time, also create a new repository in Dockerhub. The Dockerhub repository will be used later on in the lab.


Once is it created, run the following command:

```
git clone <your_repository_url>
```

Next, download the source code for the python web application. Located [HERE](../Resources/badwebapp.zip). Copy the extracted files into the git repository that you created. The file structure should look like:

```
.
├── nginx.default
└── VulnerableWebApp
    ├── badcommand
    │   ├── admin.py
    │   ├── apps.py
    │   ├── forms.py
    │   ├── __init__.py
    │   ├── migrations
    │   │   ├── 0001_initial.py
    │   │   ├── __init__.py
    │   │   └── __pycache__
    │   │       ├── 0001_initial.cpython-38.pyc
    │   │       └── __init__.cpython-38.pyc
    │   ├── models.py
    │   ├── __pycache__
    │   ├── templates
    │   │   └── badcommand
    │   │       ├── index.html
    │   │       ├── results.html
    │   │       └── test.html
    │   ├── tests.py
    │   ├── urls.py
    │   └── views.py
    ├── db.sqlite3
    ├── manage.py
    ├── requirements.txt
    ├── startup.sh
    └── VulnerableWebApp
        ├── asgi.py
        ├── __init__.py
        ├── __pycache__
        ├── settings.py
        ├── startup.sh
        ├── urls.py
        └── wsgi.py
```

This is a web application built on Django. We will use this as the base for our Docker CI/CD excersise. <br><br>


First, run the application locally to ensure that it is working properly.<br>

Install the requirements:

```
cd VulnerableWebApp
pip3 install -r requirements.txt
```

Next, start the builtin webserver:

```
python3 manage.py runserver 0.0.0.0:1337
```
Browse to the ip address of your linux VM and you should see a webpage.<br>
You can also go to http://<ip_address>:1337/test <br><br>

Great! The web application is now working. Let's now go and containerize this web application.

## Part 2 - Using Docker

In order to containerize our application, we need to create a Dockerfile. This file is responsible for choosing the base image and running any required configuration. Start by creating a Dockerfile and open it in a text editor. <br><br>


First, let's choose a base image to build our configuration on:
```
#Dockerfile
FROM  python:3.8-slim-buster
```

Next, we need to install NGINX to run as the webserver.

```
#Install NGINX
RUN apt-get update && apt-get install nginx -y --no-install-recommends
COPY nginx.default /etc/nginx/sites-available/default
```

Then we need to copy our code to the container and set the working directory.

```
RUN mkdir /VulnerableWebApp
COPY . /VulnerableWebApp


WORKDIR /VulnerableWebApp/VulnerableWebApp
```

Next, install the requirements to run the application:

```
RUN pip install -r requirements.txt
RUN chmod +x ./startup.sh
```

Finally, expose the port and run the startup script:

```
EXPOSE 8080
CMD ["./startup.sh"]
```
We now have a complete Dockerfile. Build the image by running this command:

```
sudo docker build . -t <dockerhubusername>/badwebapp
```

Confirm that you have the docker image built

```
sudo docker image list
```

Finally, let's run the container and check to see if it's working correctly:

```
sudo docker run  -d -p <DEST_PORT>:8080 <IMAGE_NAME>
```
Congratulations! You now have a containerized Web Application!

## Part 3 - Push to Github

Let's now push our code to Github. <br><br>

First add the changes you want to commit. The following command all of the changes.

```
git add -A
```

Next, we must commit the changes. Specify a message relevant, like "Initial commit".

```
git commit -m "<Update Message>"
```

Finally, let's push our committed changes to Github

```
git push
```

Next, we will build our pipeline!

## Part 4 - CI/CD Pipeline

For this part of the lab, we are going to build a basic CI/CD pipeline that will build our docker image, test it, and push it to Dockerhub. The CI/CD tool that we will be using is Github Actions, because it is built into Github. The concept is going to be the same for all CI/CD tools.<br>

First, lets create the required directory. 

```
mkdir .github
cd .github
mkdir workflows
cd workflows
```

Navigate to the new directory and create a file called pipeline.ynl. Open that file in a text editor. <br>
<b> NOTE: Follow along to see the required indentation. YAML is very specific about whitespace.</b>

Let's begin by defining the name and the trigger for the pipeline:

```
name: "My First Pipeline"

on:
  push:
    branches:
    - main
```
This means that any time there is a push to the main branch, that the pipeline will run. <br>
<br>

Next, define the job and the environment:

```
jobs:
  Pipeline-Job:
    name: 'My First Pipeline Job'
    runs-on: ubuntu-latest
```

Define the first step. This is copying the code to the runner.

```
    steps:
    - name: Checkout Code
      uses: actions/checkout@v1
```

Like before, we need to build the container. Lets at that as a step:

```
    - name: Build Docker Container
      run: |
         docker build . -t michaelbraunbass/badwebapp
```         
Next, we will run a smoke test to ensure that nothing has broken after making changes.
```
    - name: Smoke Test
      run: |
         sudo docker run  -d -p 8080:8080 michaelbraunbass/badwebapp
         sleep 5
         curl localhost:8080
```         

Now it's time to push to DockerHub. We are going to use a pre build Action. [Build-Push-Action](https://docs.github.com/en/free-pro-team@latest/actions/guides/publishing-docker-images#publishing-images-to-docker-hub)

```
    - name: Push to Docker Hub
      uses: docker/build-push-action@v1
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}
        repository: michaelbraunbass/testbadapp:latest
        
```

Commit your changes. Go to Github and navigate to the Actions Tab. You should see your pipeline running. IF everything is done correctly, you will have pushed your image to Dockerhub.

## Testing the CI/CD Pipeline

To test the pipeline, let's make a change to the code. Navigate to VulnerableWebApp > badcommand > templates > badcommand > index.html. <br><br>

Edit the webpage. Change the background color, font size, etc. Commit the changes. <br><br>

Then, pull the image from Dockerhub and run it.

```
sudo docker pull <dockerhubusername>/badwebapp:main
sudo docker run --rm -d -p 8080:8080 michaelbraunbass/testbadapp:main
```
Browse to the IP address of your Docker machine and see that the changes have been applied. <br><br>

<b>This completes Lab 1</b>