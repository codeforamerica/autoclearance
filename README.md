# Autoclearance

## Development
Clone this repository and navigate to it.

Homebrew is used to install local dependencies. [Install it here.](https://brew.sh/)
Then. run `brew bundle` from the `autoclearance` directory.

`ruby-install` and `chruby` are used to manage Ruby versions.
[Follow instructions here for autoswitching with chruby](https://github.com/postmodern/chruby#auto-switching)

Run `gem install bundler` and then `bundle` to install Ruby dependencies.

### To set up the Beanstalk CLI
To add a Elastic Beanstalk profile for the environment, add the following to `~/.aws/config`
```
[profile autoclearance]
aws_access_key_id=<your key>
aws_secret_access_key=<your secret key>
region=us-gov-west-1
```

Initialize Elastic Beanstalk
`eb init --profile autoclearance --region us-gov-west-1`

## Deploying
Create two files: `backend-config` and `varfile` to supply Amazon credentials. Examples are located at `backend-config.example` and `varfile.example`
To deploy using Terraform, cd to the terraform directory and run `terraform init -backend-config config_file`

Create a new keypair through the AWS console for SSH access to the bastion. Safely store the keyfile.
Generate a publickey for your `varfile` by running `ssh-keygen -y -f /path/to/private_key.pem`.

When the bastion is initially created, you will need to use these credentials to run the bastion setup script
with: `./bastion_setup.sh <ip address>`,
which creates individual user accounts and sets up logging to CloudWatch from the bastion.

To apply Terraform settings, run: `terraform apply -var-file varfile`

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


## To SSH to the EC2 instance via the bastion host
Add your credentials to your local SSH agent by running: `ssh-add <key>`
SSH to the instance by proxying through the Bastion by running:
`ssh -o ProxyCommand='ssh -W %h:%p <username>@<bastion public ip>' <username>@<instance private ip>`

## Notes
In order for the config rule "s3-bucket-ssl-requests-only" to be in compliance, you will need to deny HTTP access for the bucket created by Elastic Beanstalk to store application artifacts. To do this, add this policy excerpt to the created bucket.
```
{
      "Sid": "DenyUnSecureCommunications",
      "Effect": "Deny",
      "Principal": {
        "AWS": "*"
      },
      "Action": "s3:*",
      "Resource": "arn:aws-us-gov:s3:::{bucket_name}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": false
        }
      }
}
```
