# README

### Starting the app

Prerequisites are that you have Git client installed and have cloned this repo. You also need Docker for Mac installed.

1. Run `docker-compose up`
1. Visit the application at `http://localhost`

Note that you can use the `-d` switch with `docker-compose up` to detatch the running app from the terminal. This can be followed by a log output command so to run the app you can open a terminal and run the following:

`docker-compose up -d && docker-compose logs -f`

## Development

### Add a new Rails resource

Run the `rails` command line via `docker-compose` to execute the commands within the Docker image. Do this by prefixing each command with `docker-compose run --rm webapp`

For example run `docker-compose run --rm webapp bin/rails g scaffold articles title:string body:text` (change the model name and fields as per what is needed)

### Connect a terminal session to the container

Run `docker exec -it webapp bash` which will connect you a permanent terminal session to the container. Then it's possible to run `rails`, `rake` (etc) commands without the prefix (since you are 'inside' the container now).

### Test the API using cURL

Run the following to add a new article to the database via the REST API:

`curl -H "Content-Type: application/json" -X POST -d '{"title":"my brand new article","body":"This was made during a demo!"}' http://localhost/articles`

## Deploying the Production ready application to a Kubernetes Cluster on AWS 

### Initial setup - install KOPS and create a new cluster

* Install kops `brew install kops`
* In your AWS account create a KOPS IAM user with Administrator access. The name of the user can be anything. Make a note of the keys.
* In your AWS account create a subdomain hosted zone which will be used by KOPS. For example, create a new Route 53 Hosted Zone for 'k8s.stemware.io'. Then in the Hosted Zone for the parent, add a new Record Set for 'k8s.stemware.io' of type 'Nameserver' and past in the Nameserver values from the sub-domain Hosted Zone just created.
* In your AWS account create a new S3 Bucket to store the state of the k8s cluster. Give it a name 'kops-state-<some-unique-id>' e.g. 'kops-state-7665'
* Run the kops create cluster command like so: `kops create cluster --name=k8s.stemware.io --state=s3://kops-state-rt7665 --zones=ap-southeast-1a --node-count=2 --node-size=t2.micro --master-size=t2.micro --dns-zone=k8s.stemware.io`
* To actually apply the new cluster in AWS you need to run the following update command `kops update cluster k8s.stemware.io --state=s3://kops-state-rt7665  --yes`
* To edit the cluster run `kops edit cluster --name=k8s.stemware.io --state=s3://kops-state-rt7665 `
* Validate the cluster as follows `kops validate cluster`
* NOTE: To delete the cluster run the following `kops delete cluster --name=k8s.stemware.io --state=s3://kops-state-rt7665 `

## Deploy an application to the cluster

In this repo example, we can deploy the application to our running cluster of nodes in AWS by simply checking the current context of our `kubectl` command is set to our AWS cluster and then creating our services, jobs and deployments withing our cluster usign the `kubectl create` command. NOTE: this has all been scriped in a bash file (see below.

For this app we would run the following:

* Make changes to the application as necessary (see development steps above)
* Commit these changes to gitup
* Run `deploy/push.sh` to build new image and push that image to Docker Hub and deploy it to our Kubernetes Cluster.
* If there are migrations then run `deploy/migrate.sh`
* Check the logs using  `kubectl logs <POD ID>` (use `kubectl get pods` to see the pod ids)

Other commands that are useful during setup and deployment

* Check deployment status `kubectl rollout status`
* List previous deployments `kubectl rollout history`
* Undo / Rollback a deployment `kubectl rollout undo`
* Undo / Rollback to a specific version of deployment `kubectl rollout undo --to-revision=n`
* Create a configmap `ks create configmap <CONFIGMAP-NAME> --from-file=<FILE-CONTAINING-CONFIG>` for example to create a configmap for Nginx configuration run `ks create configmap niginx-config --from-file=configmap/reverseproxy.conf`
* Execute a command within a container `kubectl exec <POD-NAME> -it -- <COMMAND-TO-EXECUTE>` for example to connect to a MySQL instance in a POD called 'database' `kubectl exec <POD-NAME> -it -- mysql -u root -p` or another example, to start a bash shell in a pod called 'helloworld-deployment-5dc4bb99fd-gf8nd' `kubectl exec helloworld-deployment-5dc4bb99fd-gf8nd -it -- bash`
* Execute a command in a temp container (usually 'busybox') then run the following `kubectl run -i --tty busybox --image=busybox --restart=Never -- bash`

### Setup a new Dockarized Rails Project

NOTE: Accociated tutorial repo is [here](https://github.com/Apress/deploying-rails-w-docker/tree/master/webapp)

What follows are brief notes on how I dockarised this Rails application and pushed it to Docker Hub.

I created the application myself so I decided to install Rails on my local computer and create the application there. 

`rails new --skip-bundle --api --database postgresql`

Mote we passed `--skip-bundle` which means that the applications gem dependencies have not yet been installed and therefore there is no `Gemfile.lock`. The reason for doing this is so that we can run `bundle install` inside a Docker image like so.

`docker run --rm -v "$PWD":/usr/src/app -w /usr/src/app ruby:2.4.1 bundle install`

This will create our Gemfile.lock file. The remaining files are added and configured manually as follows:

* Add `Dockerfile`
* Add `docker-compose.yml`
* Add `webapp.conf` 
* Add `rails-env.conf`
* Add `setup.sh`
* Add a customer logger in `config\application.rb` which sends logs to STDOUT so that we can use `docker-compose logs -f` (see below for starting the app).
* Add `.dockerignore`
* Add `push.sh` file for building and pushing the Docker image to Docker Hub.

See all the above files in this repo for example content in each. Once all the above files are completed just run `./push.sh` to build and push the Docker image to Docker Hub (log into the `docker` cli tool first).

### Setup Kubernetes scripts and Minikube in a new project

The following is a high level step by step guideline to setting up Kubernetes for a new project as well as testing the deployment using minkkube

* Create directories `kube/deployments` & `kube/jobs`
* Create the deployment files  (see files in this repo for examples)
* Create the job files (see files in this repo for examples)
* Install [minikube](https://github.com/kubernetes/minikube) to test the deployment locally. Make sure that your deployment and job files use the development environment for this testing.
* Install [kubectl](https://kubernetes.io/docs/getting-started-guides/minikube/#download-kubectl)
* Install VirtualBox
* Start minikube by running `minikube start`
* Run `minikube dashboard`
* Run `kubectl create -f kube/minikube/deployments/postgres-deployment.yaml`
* Run `kubectl create -f kube/jobs/setup-job.yaml`
* Wait for the job to complete by checking the logs in the dashboard
* Run `kubectl create -f kube/deployments/webapp-deployment.yaml`
* Run `kubectl get pods` which will list all the running pods (in this project it will show one db and three webapp pods)
* Run `kubectl describe service webapp` to view details about the service created
* Run `minikube service webapp` (this will open up the application with load balancing already configured and working accross the three application pods )

### AWS CLI Tips

To query the API using the AWS CLI use the --query switch. For example, to return the instance id's of all EC2 instances, run the following:

`aws ec2 describe-instances --query='Reservations[*].Instances[*].InstanceId'`

Use filters to fetch details about a specific subset of data. For example, fetch the Subnets for a specifiv VPC as follows:

`aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-471eff20" --query="Subnets[*].SubnetId"`

`aws ec2 create-volume --region ap-southeast --availability-zone ap-southeast-1 --size 10 --volume-type gp2`

`aws ec2 describe-volumes --volume-ids vol-0a8e8fa239f1bb752 --region ap-southeast-1`