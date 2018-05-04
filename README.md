# Autoclearance

## Development
To set up a machine for development, install local dependencies by running `brew bundle`

## Deploying
Create two files: `backend-config` and `varfile` to supply Amazon credentials. Examples are located at `backend-config.example` and `varfile.example`
To deploy using Terraform, cd to the terraform directory and run `terraform init -backend-config config_file

Create a new keypair through the AWS console for SSH access to the bastion. Safely store the keyfile.
Generate a publickey for your `varfile` by running `ssh-keygen -y -f /path/to/private_key.pem`.
