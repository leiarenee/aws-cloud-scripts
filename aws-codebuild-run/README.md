### AWS Codebuild Provisioning. Start Build and tail to Log Stream.
#### MIT Licence

This shell script starts the AWS CodeBuild project and connects to its CloudWatch log stream. It can be used in Terraform to build project. The null_resource in which this script is provisioned then is used as a dependency for next step such as deployment into the Kubernetes or ECS cluster.

#### Pre-requisites

* aws [aws client tool > 2.0](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
* cw [https://github.com/lucagrulla/cw](https://github.com/lucagrulla/cw)

#### Usage

`./aws-codebuild-run.sh <codebuild-project-name>`

#### With Optional Parameters:

`./aws-codebuild-run.sh <codebuild-project-name> <aws-profile> <aws-region> <print-dots> <initial-timeout> <update-timeout> <sleep-interval> <init-wait-time>`

#### Parameter Definitions

* _codebuild-project-name_   : The name of the codebuild project. (Required)

* _aws-profile_              : AWS profile name in aws credentials file. (Optional)

* _aws-region_               : AWS region to be passed into external program calls. (Optional)

* _print-dots_               : Use 'print-dots' phrase to print dots on every sleep interval. Default active if not specified. 

* _initial-timeout_          : Number in seconds. If log stream is never updated within time interval specified in this parameter, script will terminate. Default is 60 seconds. It takes about 40-50 seconds for first data stream to come.

* _update-timeout_           : Number in seconds. If log stream is not recieved after last update exceeding update-timeout interval, script will terminate. Default is 60 seconds.

* _sleep-interval_           : Number in seconds. Waiting period in each cyle. Default value is 1 second.

* _init-wait-time_           : Number in seconds. Initial wait time to let codebuild prepare log groups.Default is 10 seconds.

* _max-log-retry_            : Maximum number of retry count for log stream creation.  Default is 6 .

_Note_ :  Use 'na' phrase to bypass an argument.

---
#### Example usage in Terraform

##### Main

```t
resource "null_resource" "codebuild_provisioner" {
  triggers = {
    value = var.run_auto_build ? timestamp() : var.run_build_token
  }
  

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = join(" ",[
      "scripts/aws-codebuild-run.sh",
      module.build.project_name,
      var.aws_profile,
      var.aws_region,
      local.log_tracker.print_dots,
      local.log_tracker.initial_timeout,
      local.log_tracker.update_timeout,
      local.log_tracker.sleep_interval,
      local.log_tracker.init_wait_time,
      local.log_tracker.max_retry_count
    ])
  }
}
```

If `run_auto_build` is `true` script always runs else run condition depends on a change in value of `run_build_token` variable which can be fed by user with the latest commit hash value of the repository.


##### Locals

```t
locals {

  log_tracker_defaults = {
    initial_timeout   = 300
    update_timeout    = 300
    sleep_interval    = 10
    init_wait_time    = 15
    max_retry_count   = 4
    print_dots        = false
  }
  
  log_tracker = merge(local.log_tracker_defaults, var.log_tracker)
  
}
```

##### Variables

```t
variable "aws_region" {
  type        = string
  default     = ""
  description = "(Optional) AWS Region, e.g. us-east-1. Used as CodeBuild ENV variable when building Docker images. For more info: http://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html"
}

variable "aws_profile" {
  type        = string
  default     = ""
  description = "(Optional) AWS Profile name as used in AWS credentials file."
}

variable "run_auto_build" {
  description = "If True, Build is run on every update."
  type        = bool
  default     = false
}

variable "run_build_token" {
  description = "Change it to initiate run."
  type        = string
  default     = ""
}

variable "log_tracker" {
  type        = map
  default     = {}
}
```

### Output

```sh
[terragrunt] 2020/12/12 17:31:15 Running command: terraform apply -var-file=inputs.tfvars.json -var replace_variables=0
module.build.random_string.bucket_prefix[0]: Refreshing state... [id=upsyvqndazfc]
module.build.data.aws_caller_identity.default: Refreshing state...
data.aws_secretsmanager_secret.repo: Refreshing state...
module.build.data.aws_iam_policy_document.permissions: Refreshing state...
aws_ecr_repository.ecr_repo: Refreshing state... [id=<my-app-name>]
module.build.data.aws_region.default: Refreshing state...
module.build.data.aws_iam_policy_document.role: Refreshing state...
module.build.aws_iam_policy.default[0]: Refreshing state... [id=arn:aws:iam::<my-aws-account-id>:policy/service-role
null_resource.codebuild_provisioner: Refreshing state... [id=8750339706677025376]
An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
-/+ destroy and then create replacement

Terraform will perform the following actions:

  # null_resource.codebuild_provisioner must be replaced
-/+ resource "null_resource" "codebuild_provisioner" {
      ~ id       = "8750339706677025376" -> (known after apply)
      ~ triggers = {
          - "value" = "4aadf62df55b0288dd5464bc57ec452275a537bb"
        } -> (known after apply) # forces replacement
    }

Plan: 2 to add, 0 to change, 2 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

shell_script.get_image_url: Destroying... [id=bvaadf3c1osjnjra00r0]
shell_script.get_image_url: Destruction complete after 0s
null_resource.codebuild_provisioner: Destroying... [id=8750339706677025376]
null_resource.codebuild_provisioner: Destruction complete after 0s
null_resource.codebuild_provisioner: Creating...
null_resource.codebuild_provisioner: Provisioning with 'local-exec'...
null_resource.codebuild_provisioner (local-exec): Executing: ["/bin/bash" "-c" "scripts/aws-codebuild-run.sh <my-codebuid-project-name> test-<my-aws-account-id> eu-central-1 false 300 300 10 15 4"]
null_resource.codebuild_provisioner (local-exec): Checking cw version
null_resource.codebuild_provisioner (local-exec): 3.3.0

null_resource.codebuild_provisioner (local-exec): Project Name: <my-codebuid-project-name>
null_resource.codebuild_provisioner (local-exec): Aws Profile: test-<my-aws-account-id>
null_resource.codebuild_provisioner (local-exec): Aws Region: eu-central-1
null_resource.codebuild_provisioner (local-exec): Print dots: false
null_resource.codebuild_provisioner (local-exec): Initial Timeout: 300
null_resource.codebuild_provisioner (local-exec): Update Timeout: 300
null_resource.codebuild_provisioner (local-exec): Sleep Interwal: 10
null_resource.codebuild_provisioner (local-exec): Initial Wait time: 15
null_resource.codebuild_provisioner (local-exec): Max Log Retry: 4
null_resource.codebuild_provisioner (local-exec): Starting to build <my-codebuid-project-name>
null_resource.codebuild_provisioner (local-exec): build_id=<my-codebuid-project-name>:485d36dc-7eee-44dc-b520-3da6d007f9f7
null_resource.codebuild_provisioner (local-exec): {
null_resource.codebuild_provisioner (local-exec):   "SUBMITTED": "SUCCEEDED",
null_resource.codebuild_provisioner (local-exec):   "QUEUED": null
null_resource.codebuild_provisioner (local-exec): }
null_resource.codebuild_provisioner (local-exec): ProvisioningStatus=
null_resource.codebuild_provisioner (local-exec): Provisioning still continues, Waiting for 15 seconds and retrying...
null_resource.codebuild_provisioner: Still creating... [10s elapsed]
null_resource.codebuild_provisioner: Still creating... [20s elapsed]
null_resource.codebuild_provisioner (local-exec): {
null_resource.codebuild_provisioner (local-exec):   "SUBMITTED": "SUCCEEDED",
null_resource.codebuild_provisioner (local-exec):   "QUEUED": "SUCCEEDED",
null_resource.codebuild_provisioner (local-exec):   "PROVISIONING": null
null_resource.codebuild_provisioner (local-exec): }
null_resource.codebuild_provisioner (local-exec): ProvisioningStatus=null
null_resource.codebuild_provisioner (local-exec): Provisioning still continues, Waiting for 15 seconds and retrying...
null_resource.codebuild_provisioner: Still creating... [30s elapsed]
null_resource.codebuild_provisioner (local-exec): {
null_resource.codebuild_provisioner (local-exec):   "SUBMITTED": "SUCCEEDED",
null_resource.codebuild_provisioner (local-exec):   "QUEUED": "SUCCEEDED",
null_resource.codebuild_provisioner (local-exec):   "PROVISIONING": "SUCCEEDED",
null_resource.codebuild_provisioner (local-exec):   "DOWNLOAD_SOURCE": "SUCCEEDED",
null_resource.codebuild_provisioner (local-exec):   "INSTALL": "SUCCEEDED",
null_resource.codebuild_provisioner (local-exec):   "PRE_BUILD": "SUCCEEDED",
null_resource.codebuild_provisioner (local-exec):   "BUILD": null
null_resource.codebuild_provisioner (local-exec): }
null_resource.codebuild_provisioner (local-exec): ProvisioningStatus=SUCCEEDED
null_resource.codebuild_provisioner (local-exec): cloudWatchLogsArn="arn:aws:logs:eu-central-1:<my-aws-account-id>:log-group:/aws/codebuild/<my-codebuid-project-name>:log-stream:485d36dc-7eee-44dc-b520-3da6d007f9f7"
null_resource.codebuild_provisioner (local-exec): Log Id: /aws/codebuild/<my-codebuid-project-name>:485d36dc-7eee-44dc-b520-3da6d007f9f7
null_resource.codebuild_provisioner (local-exec): Try count: 1
null_resource.codebuild_provisioner (local-exec): Checking log_group /aws/codebuild/<my-codebuid-project-name>
null_resource.codebuild_provisioner (local-exec): Log group exists.
null_resource.codebuild_provisioner (local-exec): Checking stream 485d36dc-7eee-44dc-b520-3da6d007f9f7
null_resource.codebuild_provisioner (local-exec): Log stream exists.
null_resource.codebuild_provisioner (local-exec): Job: 98654
null_resource.codebuild_provisioner (local-exec): Waiting for first log update.
null_resource.codebuild_provisioner: Still creating... [40s elapsed]
null_resource.codebuild_provisioner: Still creating... [50s elapsed]
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:09 Waiting for agent ping
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:11 Waiting for DOWNLOAD_SOURCE
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15 Phase is DOWNLOAD_SOURCE
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15 CODEBUILD_SRC_DIR=/codebuild/output/src044171719/src/github.com/<my-github-account-name/my-repository-name>
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15 YAML location is /codebuild/readonly/buildspec.yml
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15 Processing environment variables
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15 No runtime version selected in buildspec.
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15 Git credential helper enabled
null_resource.codebuild_provisioner (local-exec): BITBUCKET Git credential unavailable.
null_resource.codebuild_provisioner (local-exec): GITHUB_ENTERPRISE Git credential unavailable.
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15 Moving to directory /codebuild/output/src044171719/src/github.com/<my-github-account-name/my-repository-name>
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15 Expanded cache path
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15 Not a valid directory cache path:
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15 Registering with agent
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15 Phases found in YAML: 4
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15  BUILD: 4 commands
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15  POST_BUILD: 3 commands
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15  INSTALL: 1 commands
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15  PRE_BUILD: 1 commands
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15 Phase complete: DOWNLOAD_SOURCE State: SUCCEEDED
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15 Phase context status code:  Message:
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15 Entering phase INSTALL
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15 Running command if [ $CODEBUILD_BUILD_SUCCEEDING -eq 0 ];then exit 1;fi
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15 Phase complete: INSTALL State: SUCCEEDED
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15 Phase context status code:  Message:
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15 Entering phase PRE_BUILD
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15 Running command
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15 Phase complete: PRE_BUILD State: SUCCEEDED
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15 Phase context status code:  Message:
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15 Entering phase BUILD
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15 Running command if [ $CODEBUILD_BUILD_SUCCEEDING -eq 0 ];then exit 1;fi
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15 Running command echo Building the Docker image...
null_resource.codebuild_provisioner (local-exec): Building the Docker image...
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15 Running command cd $BUILD_CONTEXT
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:32:15 Running command $BUILD_FILE
null_resource.codebuild_provisioner (local-exec): - Logging into ECR
null_resource.codebuild_provisioner (local-exec): Login Succeeded
null_resource.codebuild_provisioner (local-exec): - Change branch to <my-branch-name> 
null_resource.codebuild_provisioner (local-exec): Switched to branch '<my-branch-name>'
null_resource.codebuild_provisioner (local-exec): DOCKER_IMAGE_VERSION$ = v0.1.5 
null_resource.codebuild_provisioner (local-exec): Writing 'git-info.json' 
null_resource.codebuild_provisioner (local-exec): Remote Cache Enabled 
null_resource.codebuild_provisioner (local-exec): - Downloading latest image 
null_resource.codebuild_provisioner (local-exec): latest: Pulling from <my-codebuid-project-name>
null_resource.codebuild_provisioner (local-exec): da7391352a9b: Pulling fs layer
null_resource.codebuild_provisioner (local-exec): 14428a6d4bcd: Pulling fs layer
null_resource.codebuild_provisioner (local-exec): 2c3efb18d4dc: Pulling fs layer
null_resource.codebuild_provisioner (local-exec): 7090f8531d35: Pulling fs layer
null_resource.codebuild_provisioner (local-exec): d65ac1126413: Pulling fs layer
null_resource.codebuild_provisioner (local-exec): 865f56a929de: Pulling fs layer
null_resource.codebuild_provisioner (local-exec): 2b97367cba06: Waiting
null_resource.codebuild_provisioner (local-exec): 0884ec476e39: Waiting
null_resource.codebuild_provisioner (local-exec): d65ac1126413: Waiting
null_resource.codebuild_provisioner (local-exec): 865f56a929de: Waiting
null_resource.codebuild_provisioner (local-exec): 9b38d8fe1c99: Waiting
null_resource.codebuild_provisioner (local-exec): 14428a6d4bcd: Verifying Checksum
null_resource.codebuild_provisioner (local-exec): 14428a6d4bcd: Download complete
null_resource.codebuild_provisioner (local-exec): ea11cf773a55: Verifying Checksum
null_resource.codebuild_provisioner (local-exec): ea11cf773a55: Download complete
null_resource.codebuild_provisioner (local-exec): 865f56a929de: Verifying Checksum
null_resource.codebuild_provisioner (local-exec): 865f56a929de: Download complete
null_resource.codebuild_provisioner (local-exec): 197033e79fc0: Verifying Checksum
null_resource.codebuild_provisioner (local-exec): 197033e79fc0: Download complete
null_resource.codebuild_provisioner: Still creating... [1m30s elapsed]
null_resource.codebuild_provisioner: Still creating... [1m40s elapsed]
null_resource.codebuild_provisioner: Still creating... [1m50s elapsed]
null_resource.codebuild_provisioner (local-exec): 2b97367cba06: Pull complete
null_resource.codebuild_provisioner: Still creating... [2m0s elapsed]
null_resource.codebuild_provisioner: Still creating... [2m10s elapsed]
null_resource.codebuild_provisioner: Still creating... [2m20s elapsed]
null_resource.codebuild_provisioner: Still creating... [2m30s elapsed]
null_resource.codebuild_provisioner (local-exec): f395e542f5fa: Pull complete
null_resource.codebuild_provisioner (local-exec): e747623150a5: Pull complete
null_resource.codebuild_provisioner (local-exec): 2c3efb18d4dc: Pull complete
null_resource.codebuild_provisioner (local-exec): 7090f8531d35: Pull complete
null_resource.codebuild_provisioner (local-exec): d65ac1126413: Pull complete
null_resource.codebuild_provisioner (local-exec): 865f56a929de: Pull complete
null_resource.codebuild_provisioner (local-exec): Digest: sha256:30e267b573eac8b96a019a19ef395e91b3ff82bbcbb470d122c01a405289c30c
null_resource.codebuild_provisioner (local-exec): Status: Downloaded newer image for <my-aws-account-id>.dkr.ecr.eu-central-1.amazonaws.com/<my-codebuid-project-name>:latest
null_resource.codebuild_provisioner (local-exec): <my-aws-account-id>.dkr.ecr.eu-central-1.amazonaws.com/<my-codebuid-project-name>:latest
null_resource.codebuild_provisioner (local-exec): - Building Image 
null_resource.codebuild_provisioner (local-exec): Sending build context to Docker daemon  3.846MB
null_resource.codebuild_provisioner (local-exec): Step 1/28 : FROM ubuntu:20.04
null_resource.codebuild_provisioner (local-exec): 20.04: Pulling from library/ubuntu
null_resource.codebuild_provisioner (local-exec): da7391352a9b: Already exists
null_resource.codebuild_provisioner (local-exec): 14428a6d4bcd: Already exists
null_resource.codebuild_provisioner (local-exec): 2c2d948710f2: Already exists
null_resource.codebuild_provisioner (local-exec): Digest: sha256:c95a8e48bf88e9849f3e0f723d9f49fa12c5a00cfc6e60d2bc99d87555295e4c
null_resource.codebuild_provisioner (local-exec): Status: Downloaded newer image for ubuntu:20.04
null_resource.codebuild_provisioner (local-exec):  ---> f643c72bc252
null_resource.codebuild_provisioner (local-exec): Step 2/28 : RUN apt update   && export DEBIAN_FRONTEND=noninteractive   && apt -yq install wget unzip
null_resource.codebuild_provisioner (local-exec):  ---> Using cache
null_resource.codebuild_provisioner (local-exec):  ---> f554e7ec4edd
null_resource.codebuild_provisioner (local-exec): Step 6/28 : RUN /usr/bin/unzip -q /tmp/download.zip -d ${HOME}
null_resource.codebuild_provisioner (local-exec):  ---> Using cache
null_resource.codebuild_provisioner (local-exec):  ---> 65d992b2de23
null_resource.codebuild_provisioner (local-exec): Step 7/28 : RUN rm /tmp/download.zip
null_resource.codebuild_provisioner (local-exec):  ---> Using cache
null_resource.codebuild_provisioner (local-exec):  ---> 634626266efa
null_resource.codebuild_provisioner (local-exec): Step 8/28 : RUN groupadd -r user &&     useradd -s /bin/bash -d ${HOME} -r -g user user
null_resource.codebuild_provisioner (local-exec):  ---> Using cache
null_resource.codebuild_provisioner (local-exec):  ---> 124a7102f068
null_resource.codebuild_provisioner (local-exec): Step 9/28 : RUN chown -R user:user $HOME
null_resource.codebuild_provisioner (local-exec):  ---> Using cache
null_resource.codebuild_provisioner (local-exec):  ---> 60962b01c1d1
null_resource.codebuild_provisioner (local-exec): Step 10/28 : RUN apt-get update &&     apt -yq install openjdk-8-jdk
null_resource.codebuild_provisioner (local-exec):  ---> Using cache
null_resource.codebuild_provisioner (local-exec):  ---> 298d436c2a89
null_resource.codebuild_provisioner (local-exec): Step 11/28 : RUN apt -yq install netcat dnsutils iputils-ping
null_resource.codebuild_provisioner (local-exec):  ---> Using cache
null_resource.codebuild_provisioner (local-exec):  ---> b1fd7e098303
null_resource.codebuild_provisioner (local-exec):  ---> 715c2a36f3f3
null_resource.codebuild_provisioner (local-exec): Step 13/28 : USER user
null_resource.codebuild_provisioner (local-exec):  ---> Using cache
null_resource.codebuild_provisioner (local-exec):  ---> eceae9f5e0cf
null_resource.codebuild_provisioner (local-exec): Step 14/28 : RUN mkdir $HOME/docker-entrypoint.d $HOME/templates $HOME/scripts
null_resource.codebuild_provisioner (local-exec):  ---> Using cache
null_resource.codebuild_provisioner (local-exec):  ---> 8d1159c31084
null_resource.codebuild_provisioner (local-exec): Step 27/28 : ENTRYPOINT ["../docker/docker-entrypoint.sh"]
null_resource.codebuild_provisioner (local-exec):  ---> Using cache
null_resource.codebuild_provisioner (local-exec):  ---> afd45b9c7e9f
null_resource.codebuild_provisioner (local-exec): Step 28/28 : CMD ["start.sh", "config.xml"]
null_resource.codebuild_provisioner (local-exec):  ---> Using cache
null_resource.codebuild_provisioner (local-exec):  ---> 1ab70ad06435
null_resource.codebuild_provisioner (local-exec): Successfully built 1ab70ad06435
null_resource.codebuild_provisioner (local-exec): Successfully tagged <my-aws-account-id>.dkr.ecr.eu-central-1.amazonaws.com/<my-codebuid-project-name>:v0.1.5
null_resource.codebuild_provisioner (local-exec): Successfully tagged <my-aws-account-id>.dkr.ecr.eu-central-1.amazonaws.com/<my-codebuid-project-name>:latest
null_resource.codebuild_provisioner (local-exec): Successfully tagged <my-codebuid-project-name>:latest
null_resource.codebuild_provisioner (local-exec): - Uploading Application Image 
null_resource.codebuild_provisioner (local-exec): The push refers to repository [<my-aws-account-id>.dkr.ecr.eu-central-1.amazonaws.com/<my-codebuid-project-name>]
null_resource.codebuild_provisioner (local-exec): e6365b671b53: Preparing
null_resource.codebuild_provisioner (local-exec): bacd3af13903: Preparing
null_resource.codebuild_provisioner (local-exec): 5b7293f4add1: Waiting
null_resource.codebuild_provisioner (local-exec): cd453e5b4568: Waiting
null_resource.codebuild_provisioner (local-exec): e6365b671b53: Layer already exists
null_resource.codebuild_provisioner (local-exec): 9069f84dbbe9: Layer already exists
null_resource.codebuild_provisioner (local-exec): v0.1.5: digest: sha256:30e267b573eac8b96a019a19ef395e91b3ff82bbcbb470d122c01a405289c30c size: 4713
null_resource.codebuild_provisioner (local-exec): - Uploading latest Tag 
null_resource.codebuild_provisioner (local-exec): The push refers to repository [<my-aws-account-id>.dkr.ecr.eu-central-1.amazonaws.com/<my-codebuid-project-name>]
null_resource.codebuild_provisioner (local-exec): e6365b671b53: Preparing
null_resource.codebuild_provisioner (local-exec): bacd3af13903: Preparing
null_resource.codebuild_provisioner (local-exec): 5b7293f4add1: Waiting
null_resource.codebuild_provisioner (local-exec): bacd3af13903: Waiting
null_resource.codebuild_provisioner (local-exec): 86f451bc0e2e: Layer already exists
null_resource.codebuild_provisioner (local-exec): bacd3af13903: Layer already exists
null_resource.codebuild_provisioner (local-exec): latest: digest: sha256:30e267b573eac8b96a019a19ef395e91b3ff82bbcbb470d122c01a405289c30c size: 4713
null_resource.codebuild_provisioner (local-exec): - Build Complete 
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:34:39 Phase complete: BUILD State: SUCCEEDED
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:34:39 Phase context status code:  Message:
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:34:39 Entering phase POST_BUILD
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:34:39 Running command if [ $CODEBUILD_BUILD_SUCCEEDING -eq 0 ];then exit 1;fi
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:34:39 Running command echo Build completed on `date`
null_resource.codebuild_provisioner (local-exec): Build completed on Sat Dec 12 14:34:39 UTC 2020
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:34:39 Running command printf '[{"name":"%s","imageUri":"%s"}]' $APP_NAME $REPOSITORY_URL:$latest > imagedefinitions.json
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:34:39 Phase complete: POST_BUILD State: SUCCEEDED
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:34:39 Phase context status code:  Message:
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:34:39 Phase complete: UPLOAD_ARTIFACTS State: SUCCEEDED
null_resource.codebuild_provisioner (local-exec): [Container] 2020/12/12 14:34:39 Phase context status code:  Message:

null_resource.codebuild_provisioner (local-exec): Success: Build completed succesfully.
null_resource.codebuild_provisioner: Creation complete after 3m4s [id=2441241094058006477]
shell_script.get_image_url: Creating...
shell_script.get_image_url: Creation complete after 0s [id=bvada13c1oso1g3a7k50]

Apply complete! Resources: 2 added, 0 changed, 2 destroyed.
Releasing state lock. This may take a few moments...

Outputs:

badge_url = https://codebuild.eu-central-1.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoiMlQ1R0hpU1lzZ3Z0bTRhMXpmUhbCI6MX0%3D&branch=master
cache_bucket_arn = UNSET
cache_bucket_name = UNSET
commit_hash = 4aadf62df55b0288dd5464bc57ec452275a537bb
get_image_url_out = {
  "image_url" = "<my-aws-account-id>.dkr.ecr.eu-central-1.amazonaws.com/<my-codebuid-project-name>:v0.1.5"
}
project_id = arn:aws:codebuild:eu-central-1:<my-aws-account-id>:project/<my-codebuid-project-name>
project_name = <my-codebuid-project-name>
registry_id = <my-aws-account-id>
repository_arn = arn:aws:ecr:eu-central-1:<my-aws-account-id>:repository/<my-codebuid-project-name>
repository_image_full_name_tag = <my-aws-account-id>.dkr.ecr.eu-central-1.amazonaws.com/<my-codebuid-project-name>:v0.1.5
repository_name = <my-codebuid-project-name>
repository_name_tag = latest
repository_url = <my-aws-account-id>.dkr.ecr.eu-central-1.amazonaws.com/<my-codebuid-project-name>
role_arn = arn:aws:iam::<my-aws-account-id>:role/<my-codebuid-project-name>
role_id = <my-codebuid-project-name>
```
