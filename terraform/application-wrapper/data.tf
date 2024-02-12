data "terraform_remote_state" "compute_node" {
    backend = "s3"

    config = {
        bucket  = "i3h-dev-terraform-state-v2"
        key     = "dev/github.com/Penn-I3H/python-application-template/terraform.tfstate"
        region  = "us-east-1" 
    }

}