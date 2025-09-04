#!/usr/bin/env python3
"""
Infrastructure Request Renderer
Converts infrastructure requests to Terraform configuration
Supports: S3 buckets, RDS databases, Secrets Manager, IRSA roles
"""

import sys
import json
import yaml
import re
from pathlib import Path
from typing import Dict, List, Any

def main():
    if len(sys.argv) != 7:
        print("usage: render.py <request.yaml> <account_id> <region> <oidc_provider_arn> <oidc_provider_url_without_https> <out_file>")
        sys.exit(1)

    req_path, account_id, region, oidc_arn, oidc_url, out_file = sys.argv[1:]
    
    # Load and parse request
    req = yaml.safe_load(Path(req_path).read_text())
    app = req["app"]
    env = req["env"]
    namespace = req["namespace"]
    
    # Initialize Terraform configuration
    tf_config = {
        "module": {},
        "output": {},
        "resource": {
            "aws_ssm_parameter": {}
        }
    }
    
    # Track created resources for IRSA permissions
    s3_buckets = {}
    rds_databases = {}
    secrets = {}
    
    # Process each resource
    for resource in req["resources"]:
        resource_type = resource["type"]
        
        if resource_type == "s3_bucket":
            create_s3_bucket(resource, tf_config, s3_buckets, app, env)
            
        elif resource_type == "rds_database":
            create_rds_database(resource, tf_config, rds_databases, app, env)
            
        elif resource_type == "secret":
            create_secret(resource, tf_config, secrets, app, env)
            
        elif resource_type == "irsa_role":
            create_irsa_role(resource, tf_config, s3_buckets, rds_databases, secrets, app, env, namespace, oidc_arn, oidc_url)
            
        else:
            print(f"⚠️  Unknown resource type: {resource_type}")
    
    # Write Terraform configuration
    Path(out_file).write_text(json.dumps(tf_config, indent=2))
    print(f"✅ Generated Terraform configuration: {out_file}")
    print(f"📦 Resources: {len(s3_buckets)} S3, {len(rds_databases)} RDS, {len(secrets)} Secrets")

def create_s3_bucket(resource: Dict[str, Any], tf_config: Dict, s3_buckets: Dict, app: str, env: str):
    """Create S3 bucket using the existing s3-secure module"""
    name = resource["name"]
    purpose = resource.get("purpose", "uploads")
    public_access = resource.get("public_access", False)
    
    module_name = f"s3_{sanitize_name(name)}"
    
    # Environment-based settings
    versioning = env == "prod"
    lifecycle_days = 365 if env == "prod" else 90
    server_access_logs = env == "prod"
    
    tf_config["module"][module_name] = {
        "source": "../modules/s3-secure",
        "app": app,
        "env": env,
        "name": name,
        "versioning": versioning,
        "lifecycle_days": lifecycle_days,
        "block_public_access": not public_access,
        "server_access_logs": server_access_logs
    }
    
    # SSM parameters for application access
    bucket_name_param = f"/apps/{env}/{app}/s3/{name}/name"
    add_ssm_parameter(tf_config, bucket_name_param, f"${{module.{module_name}.name}}")
    
    # Track for IRSA permissions
    s3_buckets[name] = {
        "bucket_arn": f"${{module.{module_name}.arn}}",
        "module_name": module_name
    }

def create_rds_database(resource: Dict[str, Any], tf_config: Dict, rds_databases: Dict, app: str, env: str):
    """Create RDS database - simplified for Golden Path"""
    name = resource["name"]
    engine = resource.get("engine", "postgres")
    size = resource.get("size", "small")
    
    # Size mapping to instance types (optimized for demo/cost)
    instance_type_map = {
        "small": {"dev": "db.t3.micro", "stage": "db.t3.micro", "prod": "db.t3.small"},
        "medium": {"dev": "db.t3.micro", "stage": "db.t3.small", "prod": "db.t3.medium"},
        "large": {"dev": "db.t3.small", "stage": "db.t3.medium", "prod": "db.t3.large"}
    }
    
    instance_type = instance_type_map[size][env]
    allocated_storage = 20 if env == "dev" else (20 if env == "stage" else 100)  # Minimal storage
    multi_az = False  # Disable Multi-AZ for demo (expensive)
    backup_retention = 1 if env == "dev" else (3 if env == "stage" else 7)  # Minimal backups
    
    resource_name = f"rds_{sanitize_name(name)}"
    
    # Create RDS instance directly (simpler than a module for this demo)
    tf_config["resource"].setdefault("aws_db_instance", {})[resource_name] = {
        "identifier": f"{app}-{name}-{env}",
        "engine": engine,
        "engine_version": "15.4" if engine == "postgres" else "8.0.35",
        "instance_class": instance_type,
        "allocated_storage": allocated_storage,
        "storage_type": "gp2",  # Use gp2 for demo (cheaper than gp3)
        "storage_encrypted": True,
        "db_name": sanitize_name(name).replace("-", "_"),
        "username": "admin",
        "manage_master_user_password": True,
        "multi_az": multi_az,
        "backup_retention_period": backup_retention,
        "backup_window": "03:00-04:00",
        "maintenance_window": "sun:04:00-sun:05:00",
        "deletion_protection": False,  # Disable for demo (easier cleanup)
        "skip_final_snapshot": env != "prod",
        "tags": {
            "App": app,
            "Env": env,
            "ManagedBy": "golden-platform"
        }
    }
    
    # SSM parameters
    endpoint_param = f"/apps/{env}/{app}/rds/{name}/endpoint"
    add_ssm_parameter(tf_config, endpoint_param, f"${{aws_db_instance.{resource_name}.endpoint}}")
    
    # Track for IRSA permissions (RDS uses IAM database authentication)
    rds_databases[name] = {
        "db_arn": f"${{aws_db_instance.{resource_name}.arn}}",
        "secret_arn": f"${{aws_db_instance.{resource_name}.master_user_secret[0].secret_arn}}",
        "resource_name": resource_name
    }

def create_secret(resource: Dict[str, Any], tf_config: Dict, secrets: Dict, app: str, env: str):
    """Create AWS Secrets Manager secret"""
    name = resource["name"]
    description = resource.get("description", f"Secrets for {app} {name}")
    
    secret_name = f"/apps/{env}/{app}/secrets/{name}"
    resource_name = f"secret_{sanitize_name(name)}"
    
    tf_config["resource"].setdefault("aws_secretsmanager_secret", {})[resource_name] = {
        "name": secret_name,
        "description": description,
        "tags": {
            "App": app,
            "Env": env,
            "ManagedBy": "golden-platform"
        }
    }
    
    # SSM parameter with secret ARN
    secret_arn_param = f"/apps/{env}/{app}/secrets/{name}/arn"
    add_ssm_parameter(tf_config, secret_arn_param, f"${{aws_secretsmanager_secret.{resource_name}.arn}}")
    
    # Track for IRSA permissions
    secrets[name] = {
        "secret_arn": f"${{aws_secretsmanager_secret.{resource_name}.arn}}",
        "resource_name": resource_name
    }

def create_irsa_role(resource: Dict[str, Any], tf_config: Dict, s3_buckets: Dict, rds_databases: Dict, secrets: Dict,
                    app: str, env: str, namespace: str, oidc_arn: str, oidc_url: str):
    """Create IRSA role using existing module with simplified permissions"""
    name = resource["name"]
    
    # Get resource lists from the resource
    bucket_names = resource.get("s3_buckets", [])
    database_names = resource.get("rds_databases", [])
    secret_names = resource.get("secrets", [])
    
    module_name = "irsa"
    
    # Build grants lists for the existing IRSA module (need ARNs, not names)
    s3_grants = []
    for bucket_name in bucket_names:
        if bucket_name in s3_buckets:
            # Extract ARN from module reference
            bucket_arn = s3_buckets[bucket_name]["bucket_arn"]
            s3_grants.append(bucket_arn)
    
    # RDS permissions are handled via secrets manager ARNs
    rds_secret_grants = []
    for db_name in database_names:
        if db_name in rds_databases:
            secret_arn = rds_databases[db_name]["secret_arn"]
            rds_secret_grants.append(secret_arn)
    
    secret_grants = []
    for secret_name in secret_names:
        if secret_name in secrets:
            secret_arn = secrets[secret_name]["secret_arn"]
            secret_grants.append(secret_arn)
    
    tf_config["module"][module_name] = {
        "source": "../modules/iam/irsa-role",
        "app": app,
        "env": env,
        "namespace": namespace,
        "oidc_provider_arn": oidc_arn,
        "oidc_provider_url": oidc_url,
        "grants": {
            "s3": s3_grants,
            "rds_secrets": rds_secret_grants,  # New grant type for RDS secrets
            "secrets": secret_grants
        }
    }
    
    # Output the role ARN
    tf_config["output"]["irsa_role_arn"] = {
        "value": f"${{module.{module_name}.role_arn}}"
    }
    
    # SSM parameter with role ARN
    role_arn_param = f"/apps/{env}/{app}/irsa/{name}/arn"
    add_ssm_parameter(tf_config, role_arn_param, f"${{module.{module_name}.role_arn}}")

def add_ssm_parameter(tf_config: Dict, name: str, value: str):
    """Add SSM parameter to Terraform configuration"""
    param_name = sanitize_name(name)
    tf_config["resource"]["aws_ssm_parameter"][param_name] = {
        "name": name,
        "type": "String", 
        "value": value,
        "overwrite": True,
        "tags": {
            "ManagedBy": "golden-platform"
        }
    }

def create_kind_cluster(resource: Dict[str, Any], tf_config: Dict, kind_clusters: Dict, app: str, env: str):
    """Create kind cluster using the new ec2-kind-cluster module"""
    name = resource["name"]
    instance_type = resource.get("instance_type", "t3.medium")
    key_pair = resource["key_pair"]
    
    # Environment-specific instance sizing
    env_instance_types = {
        "dev": "t3.medium",   # 2 vCPU, 4GB - ~$30/month
        "stage": "t3.large",  # 2 vCPU, 8GB - ~$60/month  
        "prod": "t3.xlarge"   # 4 vCPU, 16GB - ~$120/month
    }
    
    if instance_type == "t3.medium":  # Use environment default if not specified
        instance_type = env_instance_types.get(env, "t3.medium")
    
    resource_name = f"{app}_{env}_kind_cluster_{sanitize_name(name)}"
    
    # We'll need to create VPC resources too for a complete setup
    # For now, assume default VPC (can be enhanced later)
    tf_config["resource"]["aws_default_vpc"] = {
        f"{app}_{env}_default_vpc": {
            "enable_dns_hostnames": True,
            "enable_dns_support": True,
            "tags": {
                "Name": f"{app}-{env}-default-vpc",
                "App": app,
                "Env": env
            }
        }
    }
    
    tf_config["resource"]["aws_default_subnet"] = {
        f"{app}_{env}_default_subnet": {
            "availability_zone": "us-east-1a",  # Default AZ
            "tags": {
                "Name": f"{app}-{env}-default-subnet",
                "App": app,
                "Env": env
            }
        }
    }
    
    # Create the kind cluster
    tf_config["module"][resource_name] = {
        "source": "./modules/ec2-kind-cluster",
        "app": app,
        "env": env,
        "instance_type": instance_type,
        "key_pair_name": key_pair,
        "private_key_path": f"~/.ssh/{key_pair}.pem",  # Standard path
        "vpc_id": f"${{aws_default_vpc.{app}_{env}_default_vpc.id}}",
        "subnet_id": f"${{aws_default_subnet.{app}_{env}_default_subnet.id}}"
    }
    
    # Store cluster info for IRSA role
    kind_clusters[name] = {
        "cluster_name": f"{app}-{env}",
        "oidc_issuer": f"${{module.{resource_name}.oidc_issuer_url}}",
        "cluster_arn": f"${{module.{resource_name}.cluster_arn}}"
    }
    
    # Create SSM parameters for cluster access
    cluster_endpoint_param = f"{app}_{env}_cluster_endpoint_{sanitize_name(name)}"
    tf_config["resource"]["aws_ssm_parameter"][cluster_endpoint_param] = create_ssm_parameter(
        f"/{app}/{env}/cluster/{name}/endpoint",
        f"${{module.{resource_name}.kubernetes_endpoint}}"
    )
    
    ssh_command_param = f"{app}_{env}_ssh_command_{sanitize_name(name)}"
    tf_config["resource"]["aws_ssm_parameter"][ssh_command_param] = create_ssm_parameter(
        f"/{app}/{env}/cluster/{name}/ssh_command",
        f"${{module.{resource_name}.ssh_command}}"
    )

def sanitize_name(name: str) -> str:
    """Sanitize name for Terraform resource names"""
    return re.sub(r'[^a-zA-Z0-9_]', '_', name)

if __name__ == "__main__":
    main()