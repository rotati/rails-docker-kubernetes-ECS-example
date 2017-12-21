# README

### Starting the app

Prerequisites are that you have Git client installed and have cloned this repo. You also need Docker for Mac installed.

1. Run `docker-compose up`
1. Visit the application at `http://localhost`

Note that you can use the `-d` switch with `docker-compose up` to detatch the running app from the terminal. This can be followed by a log output command so to run the app you can open a terminal and run the following:

`docker-compose up -d && docker-compose logs -f`

## Development

### Add a new Rails resourdce

Run the `rails` command line via `docker-compose` to execute the commands within the Docker image. Do this by prefixing each command with `docker-compose run --rm webapp`

For example run `docker-compose run --rm webapp bin/rails g scaffold articles title:string body:text` (change the model name and fields as per what is needed)

### Connect a terminal session to the container

Run `docker exec -it webapp bash` which will connect you a permanent terminal session to the container. Then it's possible to run `rails`, `rake` (etc) commands without the prefix (since you are 'inside' the container now).

### Update the Docker Image

We will append the short commit SHA to the remote Docker Image name.

`./push.sh`

### Setup a new Dockarized Rails Project

NOTE: Accociated tutorial repo is [here](https://github.com/Apress/deploying-rails-w-docker)

I created the application myself so I decided to install Rails on my local computer and create the application there. 

`rails new --skip-bundle --api --database postgresql`

Mote we passed `--skip-bundle` which means that the applications gem dependencies have not yet been installed and therefore there is no `Gemfile.lock`. The reason for doing this is so that we can run `bundle install` inside a Docker image like so.

`docker run --rm -v "$PWD":/usr/src/app -w /usr/src/app ruby:2.4.1 bundle install`

This will create our Gemfile.lock file. The remaining files are added and configured manually as follows:

* Add `webapp.conf` 
* Add `rails-env.conf`
* Add `Dockerfile`
* Add `setup.sh`
* Add `docker-compose.yml`
* Add a customer logger in `config\application.rb` which sends logs to STDOUT so that we can use `docker-compose logs -f` (see below for starting the app).
* Add `.dockerignore`
* Add `push.sh` file for building and pushing the Docker image to Docker Hub.