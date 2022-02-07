#!/usr/bin/env python3

import os, time
import subprocess
from dotenv import load_dotenv
import sys

##usage
#./ecs.py backend_bootstrap
#./ecs.py jenkins_deploy
#./ecs.py destroy

#Variables.
dirname = os.path.dirname(os.path.realpath(__file__))
backend_path = os.path.join(dirname, 'terraform/backend-bootstrap')
cluster_path = os.path.join(dirname, 'terraform/cluster')
terraform_backend_commands = "terraform init && terraform apply -auto-approve && terraform output > "+dirname+"/backend.env"
terraform_cluster_commands = "terraform init && terraform apply -auto-approve"
terraform_destroy_commands = "terraform destroy -auto-approve"
cluster_backend="""terraform {{
    backend "s3" {{
        region         = "{0}"
        bucket         = "{1}"
        key            = "state.tfstate"
        dynamodb_table = "{2}"
    }}
}}"""

##backend
def backend_bootstrap():
    load_dotenv(dotenv_path=os.path.join(dirname,'dev.env'))
    os.chdir(backend_path)
    subprocess.run(terraform_backend_commands, shell=True)
    load_dotenv(dotenv_path=os.path.join(dirname,'backend.env'))
    print("""
    ### Your cluster backend is: """)
    print(cluster_backend.format(os.getenv("TF_VAR_region"),os.getenv("TF_VAR_s3_bucket"),os.getenv("TF_VAR_dynamo_db_table")))

##ECS
def cluster_deploy():
    os.chdir(dirname)
    load_dotenv(dotenv_path=os.path.join(dirname,'backend.env'))
    load_dotenv(dotenv_path=os.path.join(dirname,'dev.env'))
    os.chdir(cluster_path)
    f = open(cluster_path+"/backend.tf", "w")
    f.write(cluster_backend.format(os.getenv("TF_VAR_region"),os.getenv("TF_VAR_s3_bucket"),os.getenv("TF_VAR_dynamo_db_table")))
    f.close()
    subprocess.run(terraform_cluster_commands, shell=True)

## destroy
def destroy():
    os.chdir(dirname)
    load_dotenv(dotenv_path=os.path.join(dirname,'backend.env'))
    load_dotenv(dotenv_path=os.path.join(dirname,'dev.env'))
    os.chdir(cluster_path)
    subprocess.run(terraform_destroy_commands, shell=True)
    os.chdir(backend_path)
    subprocess.run(terraform_destroy_commands, shell=True)
    os.chdir(dirname)
    subprocess.run("rm -rf backend.env && rm -rf "+cluster_path+"/.terraform* && rm -rf "+cluster_path+"/backend.tf",shell=True)
    subprocess.run("rm -rf "+cluster_path+"/.terraform* && rm -rf "+backend_path+"/terraform.tf* && rm -rf "+backend_path+"/.terraform*",shell=True)


if str(sys.argv[1]) == "backend_bootstrap":
    try:
        print("Applying terraform backend files.")
        time.sleep(5)
        backend_bootstrap()
    except:
        print("backend not initialized")

if str(sys.argv[1]) == "jenkins_deploy":
    try:
        print("Applying the terraform cluster files.")
        time.sleep(5)
        cluster_deploy()
    except:
        print("Deploy failed, check logs.")

if str(sys.argv[1]) == "destroy":
    try:
        print("Destroying bakcned and ecs cluster.")
        print("Press ctr+c to cancel...")
        time.sleep(10)
        destroy()
    except:
        print("Destroy failed, check logs.")