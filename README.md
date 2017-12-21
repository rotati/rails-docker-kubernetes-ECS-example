# README

### Background

I created the application myself so I decided to install Rails on my local computer and create the application there. This does not have to be done again of course!

`rails new --skip-bundle --api --database postgresql`

Mote we passed `--skip-bundle` which means that the applications gem dependencies have not yet been installed and therefore there is no `Gemfile.lock`. The reason for doing this is so that we can run `bundle install` inside a Docker image like so.

`docker run --rm -v "$PWD":/usr/src/app -w /usr/src/app ruby:2.4.1 bundle install`

We then create and add basic configuration in `webapp.conf` and `rails-env.conf`.

Then I added a `Dockerfile` from the `phusion/passenger-ruby` image.

Then I added a `setup.sh` and `docker-compose` to the project. Please view for your information.