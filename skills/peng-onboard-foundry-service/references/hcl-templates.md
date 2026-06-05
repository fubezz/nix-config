# HCL Templates for Foundry Service Onboarding

These are the exact file contents to write for each environment directory. Replace:
- `<SERVICE_NAME>` → full service name (e.g. `foundry-example-service`)
- `<ABBREVIATION>` → short prefix for GCP project name (e.g. `fes` for foundry-example-service, max ~5 chars to keep GCP project name ≤30 chars)
- `<GITHUB_REPO>` → GitHub repo name (e.g. `foundry-example-service`)
- `<ENV>` → one of `dev`, `test`, `stage`, `prod`

---

## account.hcl (identical for all 4 envs)

```hcl
locals {
  billing_id = "013CD1-01023E-EB29AA"
  org_id     = "organizations/906322165281"
}
```

---

## env.hcl (only `env` value differs per directory)

```hcl
locals {
  environment = "<SERVICE_NAME>"
  prefix      = "aignx"
  env         = "<ENV>"
}
```

---

## regions/region.hcl (identical for all 4 envs)

```hcl
locals {
  region   = "europe-west4"
  location = "eu"
}
```

---

## regions/global/service-project/terragrunt.hcl (identical for all 4 envs)

```hcl
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/aignostics/terraform-modules.git//terraform-gcp-service-project?ref=v1.44.0"
}

locals {
  subnet_name = "${include.root.inputs.prefix}-${include.root.inputs.environment}-${include.root.inputs.env}"
  subnet_key  = "${include.root.inputs.region}/${local.subnet_name}"
}

dependency "host-project" {
  config_path = "${get_repo_root()}/terragrunt/projects/host-project/shared-vpc"
}

inputs = {
  billing_account_id = include.root.inputs.billing_id
  parent             = dependency.host-project.outputs.environment_folders["${include.root.inputs.environment}"]
  prefix             = include.root.inputs.prefix
  host-project       = dependency.host-project.outputs.host_project_id
  environment        = "<ABBREVIATION>-${include.root.inputs.env}" # GCP project names are limited to 30 chars; "<ABBREVIATION>" is short for "<SERVICE_NAME>"
  org_id             = include.root.inputs.org_id
  subnets_ids = [
    lookup(lookup(dependency.host-project.outputs.subnets, "${local.subnet_key}"), "id")
  ]
  project_services = [
    "run.googleapis.com", # Required when enable_cloudrun_vpc_access is enabled
  ]
  enable_cloudrun_vpc_access = true
}
```

---

## regions/global/cloud-storage/\<GITHUB_REPO\>-tf-state/terragrunt.hcl (identical for all 4 envs)

```hcl
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
  github_repo = "<GITHUB_REPO>"
  bucket_name = "${include.root.inputs.prefix}-${local.github_repo}-${include.root.inputs.env}-tf-state"
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
```
