# Lab 1 - Git, Docker, and CI/CD
Written by Michael Braun

The purpose of this lab is to learn how to use Git, Docker and build a simple CI/CD pipeline.

## Setup

In order to run this lab, please ensure you have:<br><br>
<b> Accounts: </b><br>
[Github Account](https://github.com)<br>
[Dockerhub Account](https://hub.docker.com) <br>

<b>Tools:</b><br>
Docker<br>
Git <br>
Python 3<br>
<br>

This can all be done on either Windows or Linux. Either way, please make sure you have all the tools defined above. I've include configure.sh that installs all the tools on linux in the resources folder.


## Part 1 - Web Application

First, fork this respository: [badwebapp](https://github.com/metalstormbass/badwebapp)

Once is it created, run the following command:

```
git clone https://github.com/<YOUR_GITHUB_USERNAME>/badwebapp.git
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
You can also go to http://<docker_host_ip_address>:1337/test to see the vulnerable function.<br><br>

Great! The web application is now working. Let's now go and containerize this web application.

## Part 2 - Using Docker

In order to containerize our application, we need to create a Dockerfile. This file is responsible for choosing the base image and running any required configuration. Start by creating a Dockerfile <b>in the root of the directory</b> and open it in a text editor. We will build up the docker file.<br><br>


Open "Dockerfile" and lets being by defining a base image to build our configuration on:
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
We now have a complete Dockerfile. The complete Dockerfile should look like:

```
#Dockerfile
FROM python:3.8-slim-buster

#Install NGINX
RUN apt-get update && apt-get install nginx -y --no-install-recommends
COPY nginx.default /etc/nginx/sites-available/default

RUN mkdir /VulnerableWebApp
COPY . /VulnerableWebApp
 
WORKDIR /VulnerableWebApp/VulnerableWebApp

RUN pip install -r requirements.txt
RUN chmod +x ./startup.sh

EXPOSE 8080
CMD ["./startup.sh"]
```

Build the image by running this command:

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
Confirm that image is running"

```
sudo docker image list
```

Browse to http://<docker_host_ip_address>:8080 and you will see the home page. Also, try going to http://<docker_host_ip_address>:8080/test to see the vulnerable fuction. <br>

Congratulations! You now have a containerized Web Application! 

## Part 3 - Push to Github

Let's now push our code to Github. <br><br>

<b>Note:</b> You may have some issues if you email address is set to private or if you have two factor authentication enabled. 

First, set up git, run:
```
git config -global user.email <your_githube_mailaddress>
git config -global user.name <your_name>
```

You must add the changes you want to commit. The following command will add all of the changes.

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

<b>Note:</b> You can set up SSH authencation by follwing these steps. [SSH Authentication for Github](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account)

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
         docker build . -t <dockerhubusername>/badwebapp
```         
Next, we will run a smoke test to ensure that nothing has broken after making changes.
```
    - name: Smoke Test
      run: |
         sudo docker run  -d -p 8080:8080 <dockerhubusername>/badwebapp
         sleep 5
         curl localhost:8080
```         

Now it's time to push to DockerHub. We are going to use a pre build Action. [Build-Push-Action](https://github.com/docker/build-push-action)

```
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
        tags: <dockerhubusername>/badwebapp
```

Commit your changes. Go to Github and navigate to the Actions Tab. You should see your pipeline running. IF everything is done correctly, you will have pushed your image to Dockerhub.

## Testing the CI/CD Pipeline

To test the pipeline, let's make a change to the code. Navigate to VulnerableWebApp > badcommand > templates > badcommand > index.html. <br><br>

Edit the webpage. Change the background color, font size, etc. Commit the changes. <br><br>

Then, pull the image from Dockerhub and run it.

```
sudo docker pull <dockerhubusername>/badwebapp:latest
sudo docker run -d -p 8080:8080 <dockerhubusername>/badwebapp:latest
```
Browse to the IP address of your Docker machine and see that the changes have been applied. <br><br>

<b>Bonus Challenge:</b> Try to add a build status badge to your README.md file

<b>This completes Lab 1!</b>