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


## Part 1 - Web Application

First, let's create a new repository on Github. It can be a public repository as there is nothing confidential. Once is it created, run the following command:

```
git clone <your_repository_url>
```

Next, download the source code for the python web application. Located HERE. Copy the extracted files into the git repository that you created. The file structure should look like:

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
sudo docker run --rm -d -p <DEST_PORT>:8080 <IMAGE_NAME>
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
## 