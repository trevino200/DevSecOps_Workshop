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


First, run the application locally to ensure that it is working properly.

Install the requirements:

```
cd VulnerableWebApp
pip3 install -r requirements.txt
```

Next, start the builtin webserver:

```
python3 manage.py runserver 0.0.0.0:1337
```
