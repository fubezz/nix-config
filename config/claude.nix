{ ... }:

{
  home.file.".claude/CLAUDE.md".text = ''
    # Global Coding & Infrastructure Best Practices

    ## Skills & Marketplace

    - The company shares Claude Code skills via the private marketplace at https://github.com/aignostics/claude-marketplace.
    - When looking for skills or building new ones, check the marketplace first.

    ---

    ## Tooling

    - The team uses **mise** for managing tool versions across repositories.
    - Fabian personally uses **Nix** — missing tools are installed globally via the `nix-config` repository.

    ---

    ## Debugging & CLI Tools

    - **Jira** — use `acli` for debugging and scripting Jira interactions.
    - **Kubernetes** — use `kubectl` for debugging cluster resources.
    - **ArgoCD** — use `argocd` CLI for checking application and sync states across clusters. Instance runs at `argocd.aignx.com`.
    - **GCP** — use `gcloud` for debugging and inspecting Google Cloud resources.

    ---

    ## Pull Request Workflow

    Applies to the **infrastructure** and **gitops** repositories:

    1. After creating a PR, spawn a **new agent with fresh context** to review the changes and PR description.
    2. The review agent must **post inline comments** on the PR.
    3. Once the review agent finishes, **read its comments** and improve the PR accordingly.
    4. For infrastructure PRs, use the **`/review-infra-pr`** skill as the starting point for the review agent.

    ---

    ## General

    - The **owner label** on all resources must be `bp_pe`.
    - **GitHub Actions** must be pinned to a specific **commit SHA** (not a tag or branch).
    - **Docker images** must always be pinned to a specific digest or immutable tag — never `latest`.
    - Commits must follow **Conventional Commits** format and always include a ticket reference. If no ticket exists, create one in Jira before committing.
    - Branch names must follow the format: `<type>(<TICKET>): short-description`, where `<type>` is a conventional commit type (e.g. `feat`, `fix`, `chore`, `refactor`) and `<TICKET>` is a Jira ticket key (e.g. `OP-123`). The default space for platform engineering is `OP`, but other spaces may apply depending on the context. Always scoped to a ticket — if none exists, create one in Jira first.

    ---

    ## Infrastructure Repository

    Manages GCP infrastructure with **Terragrunt**, deployed via **Atlantis** — never apply terraform/terragrunt manually.

    ### Modules

    - Reference modules come from the **terraform-modules repository** or official upstream modules. Do NOT use the legacy `/modules` folder inside the infrastructure repo.
    - Prefer **official Google modules** over writing custom ones. For GKE clusters, use the [`private-cluster-update-variant`](https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine/google/latest/submodules/private-cluster-update-variant) module from Google.
    - If a custom module must be written, it belongs in the **terraform-modules repository** — never in the local infrastructure repo. This ensures quality control, versioning, and testability.

    ### Networking (Shared VPC)

    - We run GCP with a **Shared VPC** hosted in the host project. IP ranges are centrally managed — do not create ad-hoc ranges. Always check availability in the [IP range spreadsheet](https://docs.google.com/spreadsheets/d/1w9-ZVuCVe2d9Am8LZ43Hs52T0fwsdddcKv2HzbQzy8k/edit?gid=1928991210#gid=1928991210) before allocating new subnets.
    - Changes to the **host network** (Shared VPC, subnets, IP ranges) must always include `[ignore-dependencies]` in the commit message to prevent Atlantis from triggering a full plan of the entire repository.

    ### Foundry Projects

    - A **Foundry project** is a set of GCP projects (dev, test, stage, prod) provisioned for a new service.
    - To onboard a new Foundry service, use the **`/peng-onboard-foundry-service`** skill. It handles Jira ticket creation, shared VPC subnets, service project directories, Terraform state buckets, and Atlantis allowlist setup.
    - To decommission a Foundry service, use the **`/peng-decommission-foundry-service`** skill.
    - Skills live at `infrastructure/.claude/skills/`.

    ### Policies

    - Atlantis runs **policy checks** on all changes in the infrastructure repo and Foundry templated repos.
    - Policies are defined in the **infra-policies repository** using **OPA (Open Policy Agent)**.
    - Policies currently **warn but do not block** — however, warnings are real violations and must be resolved, not ignored.

    ### Reviewing PRs

    - Always use the `/review-infra-pr` skill to review infrastructure pull requests. Never review them manually — use the skill and look for opportunities to improve it based on what you learn.

    ---

    ## GitOps Repository

    Contains Kubernetes manifests deployed by **ArgoCD**.

    ### Commit Rules

    - Enforces **pre-commit gitlint** — every commit must follow Conventional Commits format without exception.
    - The gitlint rule requires an `@aignostics.com` author email. Always set git identity before committing:
      ```bash
      git config --global user.email "fabian@aignostics.com"
      git config --global user.name "Fabian Spieß"
      ```
      The default Claude identity (`noreply@anthropic.com`) will fail the lint check.
    - When rewriting commits, always pass `--author` explicitly:
      ```bash
      git commit --amend --author="Fabian Spieß <fabian@aignostics.com>" ...
      ```
    - Do **not** use MCP `push_files` for commits that require a specific author — it uses the GitHub account's primary email and cannot be overridden.

    ---

    ## Terraform-Modules Repository

    - Contains all custom Terraform modules. Any module that cannot be sourced from an official provider must be written here, not inline in the infrastructure repo.
    - Enables quality control, versioning, and testing of shared modules.
  '';
}
