#!/usr/bin/env bash
# create_project_dirs.sh
# Creates the 4 terragrunt environment directories for a new Foundry service.
#
# Usage:
#   ./create_project_dirs.sh <service_name> <abbreviation> <github_repo> <repo_root>
#
# Example:
#   ./create_project_dirs.sh foundry-example-service fes foundry-example-service /Users/me/git/infrastructure
#
# Creates under <repo_root>/terragrunt/projects/:
#   aignx-<service_name>-{dev,test,stage,prod}/
#     account.hcl
#     env.hcl
#     regions/region.hcl
#     regions/global/service-project/terragrunt.hcl
#     regions/global/cloud-storage/<github_repo>-tf-state/terragrunt.hcl

set -euo pipefail

SERVICE_NAME="${1:?Usage: $0 <service_name> <abbreviation> <github_repo> <repo_root>}"
ABBREVIATION="${2:?}"
GITHUB_REPO="${3:?}"
REPO_ROOT="${4:?}"

PROJECTS_DIR="$REPO_ROOT/terragrunt/projects"

for ENV in dev test stage prod; do
  DIR="$PROJECTS_DIR/aignx-${SERVICE_NAME}-${ENV}"
  echo "Creating $DIR ..."

  mkdir -p "$DIR/regions/global/service-project"
  mkdir -p "$DIR/regions/global/cloud-storage/${GITHUB_REPO}-tf-state"

  # account.hcl
  cat > "$DIR/account.hcl" <<'EOF'
locals {
  billing_id = "013CD1-01023E-EB29AA"
  org_id     = "organizations/906322165281"
}
EOF

  # env.hcl
  cat > "$DIR/env.hcl" <<EOF
locals {
  environment = "${SERVICE_NAME}"
  prefix      = "aignx"
  env         = "${ENV}"
}
EOF

  # regions/region.hcl
  cat > "$DIR/regions/region.hcl" <<'EOF'
locals {
  region   = "europe-west4"
  location = "eu"
}
EOF

  # regions/global/service-project/terragrunt.hcl
  cat > "$DIR/regions/global/service-project/terragrunt.hcl" <<EOF
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/aignostics/terraform-modules.git//terraform-gcp-service-project?ref=v1.44.0"
}

locals {
  subnet_name = "\${include.root.inputs.prefix}-\${include.root.inputs.environment}-\${include.root.inputs.env}"
  subnet_key  = "\${include.root.inputs.region}/\${local.subnet_name}"
}

dependency "host-project" {
  config_path = "\${get_repo_root()}/terragrunt/projects/host-project/shared-vpc"
}

inputs = {
  billing_account_id = include.root.inputs.billing_id
  parent             = dependency.host-project.outputs.environment_folders["\${include.root.inputs.environment}"]
  prefix             = include.root.inputs.prefix
  host-project       = dependency.host-project.outputs.host_project_id
  environment        = "${ABBREVIATION}-\${include.root.inputs.env}" # GCP project names are limited to 30 chars; "${ABBREVIATION}" is short for "${SERVICE_NAME}"
  org_id             = include.root.inputs.org_id
  subnets_ids = [
    lookup(lookup(dependency.host-project.outputs.subnets, "\${local.subnet_key}"), "id")
  ]
  project_services = [
    "run.googleapis.com", # Required when enable_cloudrun_vpc_access is enabled
  ]
  enable_cloudrun_vpc_access = true
}
EOF

  # regions/global/cloud-storage/<github_repo>-tf-state/terragrunt.hcl
  cat > "$DIR/regions/global/cloud-storage/${GITHUB_REPO}-tf-state/terragrunt.hcl" <<EOF
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/aignostics/terraform-modules.git//terraform-gcp-cloud-storage?ref=v1.44.0"
}

dependency "service-project" {
  config_path                             = "../../service-project"
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "show"]
  mock_outputs = {
    project_id = "MOCK_PROJECT_ID"
  }
}

locals {
  github_org  = "aignostics"
  github_repo = "${GITHUB_REPO}"
  bucket_name = "\${include.root.inputs.prefix}-\${local.github_repo}-\${include.root.inputs.env}-tf-state"
}

# Each repo in this project gets its own bucket so state is isolated per repository.
inputs = {
  name                     = local.bucket_name
  project_id               = dependency.service-project.outputs.project_id
  location                 = include.root.inputs.location
  force_destroy            = false
  public_access_prevention = "enforced"
  storage_class            = "STANDARD"

  versioning_single = true

  soft_delete_policy = {
    retention_duration_seconds = 604800 # 7 days
  }

  labels = {
    managed_by  = "terraform"
    env         = include.root.inputs.env
    owner       = "bp_pe" # Platform Engineering
    github_org  = local.github_org
    github_repo = local.github_repo
    purpose     = "tf-state"
  }

  iam_members = []
}
EOF

  echo "  Done: $DIR"
done

echo ""
echo "All 4 directories created. Next:"
echo "  1. git add terragrunt/projects/aignx-${SERVICE_NAME}-*"
echo "  2. git commit -m 'feat(<TICKET>): add <service_name> service project dirs (dev/test/stage/prod)'"
echo "  3. git push"
