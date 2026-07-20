{ ... }:

{
  home.file.".claude/settings.json".text = builtins.toJSON {
    model = "sonnet[1m]";
    skipWorkflowUsageWarning = true;
    permissions = {
      allow = [
        "Bash(gcloud* list*)"
        "Bash(gcloud* describe*)"
        "Bash(gcloud* get*)"
        "Bash(kubectl get *)"
        "Bash(kubectl describe *)"
        "Bash(kubectl logs *)"
        "Bash(kubectl top *)"
        "Bash(kubectl config view*)"
        "Bash(kubectl config get*)"
        "Bash(kubectl cluster-info)"
        "Bash(kubectl api-resources*)"
        "Bash(kubectl explain *)"
        "Bash(kubectl version*)"
        "Bash(kubectl * --context gke_aignx-sandbox-owwexnqmwn_europe-west1_sandbox*)"
        "Bash(kubectl --context gke_aignx-sandbox-owwexnqmwn_europe-west1_sandbox* *)"
      ];
      ask = [
        "Bash(kubectl*)"
        "Bash(gcloud*)"
        "Bash(gh api *-X POST*)"
        "Bash(gh api *-X PATCH*)"
        "Bash(gh api *-X DELETE*)"
        "Bash(gh api *-X PUT*)"
        "Bash(gh api *--method POST*)"
        "Bash(gh api *--method PATCH*)"
        "Bash(gh api *--method DELETE*)"
        "Bash(gh api *--method PUT*)"
        "Bash(curl *-X POST*)"
        "Bash(curl *-X PUT*)"
        "Bash(curl *-X DELETE*)"
        "Bash(curl *-X PATCH*)"
        "Bash(curl *--request POST*)"
        "Bash(curl *--request PUT*)"
        "Bash(curl *--request DELETE*)"
        "Bash(curl *--request PATCH*)"
        "Bash(curl *--request=POST*)"
        "Bash(curl *--request=PUT*)"
        "Bash(curl *--request=DELETE*)"
        "Bash(curl *--request=PATCH*)"
        "Bash(curl *-d *)"
        "Bash(curl *--data *)"
        "Bash(curl *--data-binary *)"
        "Bash(curl *--data-raw *)"
        "Bash(curl *--data-urlencode *)"
        "Bash(curl *--upload-file *)"
        "Bash(curl *-T *)"
        "Bash(curl *-F *)"
        "Bash(curl *--form *)"
        "Bash(kubectl apply *)"
        "Bash(kubectl delete *)"
        "Bash(kubectl patch *)"
        "Bash(kubectl edit *)"
        "Bash(kubectl exec *)"
        "Bash(kubectl scale *)"
        "Bash(kubectl rollout *)"
        "Bash(kubectl label *)"
        "Bash(kubectl annotate *)"
        "Bash(kubectl taint *)"
        "Bash(kubectl drain *)"
        "Bash(kubectl cordon *)"
        "Bash(kubectl uncordon *)"
        "Bash(kubectl create *)"
        "Bash(kubectl replace *)"
        "Bash(kubectl port-forward *)"
        "Bash(kubectl cp *)"
      ];
    };
    hooks = {
      PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "rtk hook claude";
            }
          ];
        }
      ];
    };
  };

  home.file.".claude/CLAUDE.md".text = ''
    # Global Coding & Infrastructure Best Practices

    ## Skills & Marketplace

    - The company shares Claude Code skills via the private marketplace at https://github.com/aignostics/claude-marketplace.
    - When looking for skills or building new ones, check the marketplace first.
    - After creating any Jira ticket, always run the `/review-ticket-human` skill to improve it before moving on.

    ---

    ## Tooling

    - The team uses **mise** for managing tool versions across repositories.
    - Fabian personally uses **Nix** — missing tools are installed globally via the `nix-config` repository.
    - `~/.claude/CLAUDE.md` is managed by Nix home-manager — **never edit it directly**. Always edit `config/claude.nix` in the nix-config repository, then commit and run `nixrebuild`.
    - Two aliases are configured for managing the nix setup (defined in `config/shell.nix`):
      - `nixupdate` — updates the flake inputs
      - `nixrebuild` — rebuilds and switches to the new system configuration
    - After every commit to the nix-config repository, always run `nixrebuild`.

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

    ## Observability

    - The observability stack is managed in the **gitops repository** and consists of **Prometheus**, **Thanos**, **OpenTelemetry**, and **Grafana**.
    - Grafana dashboards can be provisioned via a Helm chart.

    ---

    ## Sandbox

    - **"Sandbox"** refers to the GKE cluster `gke_aignx-sandbox-owwexnqmwn_europe-west1_sandbox` and its GitOps repo at `/Users/fabian/git/sandbox-gitops` (`https://github.com/aignostics/sandbox-gitops`).
    - Sandbox PRs can be merged without an approval — merge directly after creating.
    - ArgoCD for the sandbox cluster is configured in the **normal gitops repository** (not sandbox-gitops).
    - The sandbox ArgoCD app-of-apps reads from `app-manifests/` in sandbox-gitops, tracking `HEAD` (main branch).
    - Active OTel overlay: `applications/open-telemetry-collector/overlays/sandbox-helm` in **sandbox-gitops** (not the main gitops repo), deployed via sandbox-gitops's own `app-manifests/open-telemetry-collector-charts.yaml` ApplicationSet (cluster `sandbox`, targeting `https://kubernetes.default.svc` — the main gitops repo's `open-telemetry-collector-charts` ApplicationSet has no `sandbox` entry at all).
    - **Sandbox has its own fully separate Grafana/Loki/Tempo stack**, distinct from the fleet-wide `grafana.aignostics.ai`: deployed via `app-manifests/grafana.yaml` + `grafana-loki.yaml` + `grafana-tempo.yaml` in sandbox-gitops, reachable at `grafana-sandbox.aignostics.ai`, backed by in-cluster `grafana-loki`/`grafana-tempo` Helm releases. The Grafana MCP connection (`grafana.aignostics.ai`) only ingests from the main fleet clusters (`aignx-papi-*`, `pelago-*`, `development-cluster`, etc.) and **cannot see sandbox telemetry at all** — querying it for sandbox data returns confidently empty results, not an error. To verify telemetry actually reaching the sandbox OTel collector, `kubectl --context gke_aignx-sandbox-owwexnqmwn_europe-west1_sandbox -n open-telemetry` directly: read the `debug` exporter's own pod logs for live span/log content, and check `otelcol_exporter_sent_*` / `otelcol_exporter_send_failed_*` counters on the collector's `:8888/metrics` (port-forward first — no shell/curl in the collector image) to confirm end-to-end delivery into the sandbox's own Loki/Tempo.

    ---

    ## Terraform-Modules Repository

    - Contains all custom Terraform modules. Any module that cannot be sourced from an official provider must be written here, not inline in the infrastructure repo.
    - Enables quality control, versioning, and testing of shared modules.

    @RTK.md
  '';
}
