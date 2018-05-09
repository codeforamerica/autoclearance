# Autoclearance

## Development
To set up a machine for development, install local dependencies by running `brew bundle`

To install the Beanstalk CLI, first instantiate a Python virtualenv by running:

```
python3 -m venv .venv
. .venv/bin/activate
```
Install the EB CLI by running:
`pip install awsebcli`

To add a Elastic Beanstalk profile for the environment, add the following to `~/.aws/config`
```
[profile autoclearance]
aws_access_key_id=<your key>
aws_secret_access_key=<your secret key>
region=us-gov-west-1
```

## Deploying
Create two files: `backend-config` and `varfile` to supply Amazon credentials. Examples are located at `backend-config.example` and `varfile.example`
To deploy using Terraform, cd to the terraform directory and run `terraform init -backend-config config_file

Create a new keypair through the AWS console for SSH access to the bastion. Safely store the keyfile.
Generate a publickey for your `varfile` by running `ssh-keygen -y -f /path/to/private_key.pem`.

To push a new revision to Beanstalk:
First, you must have activated your virtualenv and initialized the EB CLI:

```
. .venv/bin/activate`
eb init -r us-gov-west-1 --profile autoclearance
```

Set your Elastic Beanstalk environment by running:
`eb use <environment name> --profile autoclearance`

Deploy code to environment by running from the repository root:
`eb deploy`
