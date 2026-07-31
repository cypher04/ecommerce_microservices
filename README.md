# Ecommerce Microservices on Azure (AKS + Terraform + Helm)

A five-service Node.js ecommerce demo, containerised and deployed to **Azure Kubernetes Service**, with all
infrastructure defined in **Terraform** modules and all workloads packaged as **Helm** charts. Public traffic
enters through **Application Gateway for Containers (AGC)** via the Kubernetes **Gateway API**, and data lives
in a private **PostgreSQL Flexible Server** reachable only from inside the VNet.

---

## Table of contents

- [Architecture](#architecture)
- [Repository layout](#repository-layout)
- [The applications](#the-applications)
- [API reference](#api-reference)
- [Running locally with Docker Compose](#running-locally-with-docker-compose)
- [Azure infrastructure](#azure-infrastructure)
- [Traffic flow](#traffic-flow)
- [Deploying to Azure](#deploying-to-azure)
- [Building and pushing images](#building-and-pushing-images)

---

## Architecture

```
                    Internet
                       │
                       ▼
        ┌──────────────────────────────┐
        │  App Gateway for Containers  │  agc subnet 10.0.5.0/24 (delegated)
        │  + WAF policy (Detection)    │  Microsoft_DefaultRuleSet 2.1
        └──────────────┬───────────────┘
                       │  ALB Controller reconciles Gateway/HTTPRoute
                       ▼
        ┌──────────────────────────────────────────────┐
        │  AKS  (ecommerce-aks-cluster)                │  aks subnet 10.0.4.0/24
        │  namespace: ecommerce-app                    │
        │                                              │
        │   Gateway "shared-gateway" (HTTP :80)        │
        │     ├── HTTPRoute /frontend → frontend :3000 │
        │     ├── HTTPRoute /auth     → auth     :3001 │
        │     ├── HTTPRoute /product  → product  :3002 │
        │     ├── HTTPRoute /order    → order    :3003 │
        │     └── HTTPRoute /payment  → payment  :3004 │
        │                                              │
        │  namespace: azure-alb-system → alb-controller│
        └──────────────┬───────────────────────────────┘
                       │ NSG: allow AKS → DB :5432
                       ▼
        ┌──────────────────────────────┐
        │  PostgreSQL Flexible Server  │  db subnet 10.0.3.0/24 (delegated)
        │  ecommerce-db-2, no public   │  privatelink.postgres.database.azure.com
        │  network access              │
        └──────────────────────────────┘

  ACR (Premium) ── private endpoint in app subnet 10.0.2.0/24
                   privatelink.azurecr.io, AcrPull granted to AKS kubelet identity
  Log Analytics ── AKS oms_agent ships container insights
```

Identity wiring: the AKS cluster runs with `oidc_issuer_enabled` and `workload_identity_enabled`. A
user-assigned identity (`ecommerce-alb-identity`) is federated to the
`system:serviceaccount:azure-alb-system:alb-controller-sa` subject, and is granted **Network Contributor** plus
**AppGw for Containers Configuration Manager** on the load balancer — that is what lets the in-cluster ALB
controller program AGC from Gateway API objects.

## Repository layout

```
.
├── apps/                     Node.js services + docker-compose for local dev
│   ├── auth-service/         JWT auth, users table         :3001
│   ├── product-service/      Product catalogue             :3002
│   ├── order-service/        Orders + order items          :3003
│   ├── payment-service/      Mock payments (stateless)     :3004
│   ├── frontend/             Bootstrap 5 static UI + Express :3000
│   └── docker-compose.yml    Full local stack incl. Postgres 16
│
├── env/
│   ├── dev/                  The only wired-up environment (root module)
│   ├── stage/                Empty stubs
│   └── prod/                 Empty stubs
│
├── backend/                  Remote-state bootstrap (storage account + container)
│
├── modules/
│   ├── networking/           VNet, 5 subnets, public IP
│   ├── aks/                  AKS cluster, extra node pool, namespaces, DB secret
│   ├── agc/                  App Gateway for Containers, frontend, WAF, role assignments
│   ├── compute/              ACR (Premium) + Ubuntu jump VM
│   ├── database/             PostgreSQL Flexible Server + database
│   ├── private_endpoint/     Private DNS zones + ACR private endpoint
│   ├── security/             NSGs, subnet associations, NSG rules
│   └── monitoring/           Log Analytics workspace
│
├── helm/
│   ├── ecommerce-app/        Shared chart — owns the Gateway resource
│   ├── apps-frontend/        One chart per service: Deployment, Service,
│   ├── apps-auth-service/    HTTPRoute, ServiceAccount, HPA, probes
│   ├── apps-product-service/
│   ├── apps-order-service/
│   └── apps-payment-service/
│
├── workspace/                VS Code multi-root workspace files
└── create_structure.sh       Original scaffolding script (historical)
```

## The applications

All five services are Express apps on Node 20, built from an identical multi-stage Dockerfile that runs as a
non-root `appuser` (uid 1001). Each exposes `/livez` (liveness, always 200) and `/health` (readiness; the
DB-backed services check their connection pool). Logging is Winston + morgan.

| Service | Port | Persistence | Notes |
|---|---|---|---|
| `auth-service` | 3001 | `auth.users` | bcrypt hashing, issues JWTs (`JWT_EXPIRES_IN`, default 24h) |
| `product-service` | 3002 | `products.products` | Reads are public, writes require a valid JWT |
| `order-service` | 3003 | `orders.orders`, `orders.order_items` | Calls product + payment services via clients in `src/clients/` |
| `payment-service` | 3004 | none | Mock processor, no database dependency |
| `frontend` | 3000 | none | Serves `public/` and a `/api/config` endpoint the browser uses to discover backend URLs |

Each DB-backed service ships a `npm run init-db` script that creates its schema and tables idempotently
(`CREATE TABLE IF NOT EXISTS`). There is no migration tool — `init-db` is the schema source of truth.

## API reference

```
auth-service
  POST   /api/auth/register        { name, email, password }
  POST   /api/auth/login           { email, password } → { token, user }
  GET    /api/auth/me              Bearer token required

product-service
  GET    /api/products
  GET    /api/products/:id
  POST   /api/products             auth required
  PUT    /api/products/:id         auth required
  DELETE /api/products/:id         auth required

order-service
  POST   /api/orders               auth required
  GET    /api/orders               auth required
  GET    /api/orders/:id           auth required

payment-service
  POST   /api/payments/process
  GET    /api/payments/:id

all services
  GET    /health                   readiness (DB-backed services verify the pool)
  GET    /livez                    liveness
```

`product-service` and `order-service` verify tokens with the same `JWT_SECRET` as `auth-service`, so the secret
must be identical across all three.

## Running locally with Docker Compose

The compose file brings up Postgres 16 plus all five services with a healthcheck gate on the database:

```bash
cd apps
docker compose up --build
```

Then initialise the schemas (once, after the containers are healthy):

```bash
docker compose exec auth-service    npm run init-db
docker compose exec product-service npm run init-db
docker compose exec order-service   npm run init-db
```

Open http://localhost:3000. Individual services are also reachable on 3001–3004.

To run a service directly on the host instead, copy its `.env.example` to `.env`, point `DB_HOST` at your
Postgres, then `npm install && npm run dev` (uses `node --watch`).

## Azure infrastructure

Everything is provisioned from `env/dev`, which composes the modules under `modules/`. Providers are pinned:
azurerm `4.67.0`, kubernetes `3.0.1`, helm `3.1.1`. The kubernetes and helm providers are configured from the
AKS module's kubeconfig outputs, so a single `terraform apply` provisions the cluster **and** installs the
charts into it.

**Networking** — one VNet (`10.0.0.0/16`) with five subnets:

| Subnet | CIDR | Purpose |
|---|---|---|
| `web` | 10.0.1.0/24 | Jump VM NIC |
| `app` | 10.0.2.0/24 | ACR private endpoint |
| `database` | 10.0.3.0/24 | Delegated to `Microsoft.DBforPostgreSQL/flexibleServers` |
| `aks` | 10.0.4.0/24 | AKS node pools (Azure CNI, service CIDR 10.2.0.0/16) |
| `agc` | 10.0.5.0/24 | Delegated to `Microsoft.ServiceNetworking/trafficControllers` |

**AKS** — `ecommerce-aks-cluster`, Free tier, system-assigned identity, OIDC issuer and workload identity
enabled. Default node pool of 1 × `Standard_A2_v2` plus an `additional` autoscaling pool (1–3). The module also
creates the `ecommerce-app` and `azure-alb-system` namespaces, the `basic-auth` secret holding database
credentials, an `AcrPull` role assignment for the kubelet identity, and a `local-exec` that runs
`az aks get-credentials` after the cluster is created.

**Database** — PostgreSQL Flexible Server 12, `B_Standard_B1ms`, 32 GB P4 storage, zone 2,
`public_network_access_enabled = false`, delegated into the database subnet and attached to the
`privatelink.postgres.database.azure.com` private DNS zone.

**Security** — NSGs on the aks, web and database subnets. Rules allow AKS → DB on 5432, deny AGC → DB on 5432,
and allow DB → AKS on 80–443. A large commented-out `azurerm_application_gateway` block is the pre-AGC design,
kept for reference.

**Remote state** — `backend/` provisions the state backing store: resource group `ecommerceprojectdev-rg`,
storage account `ecommerceprojectstatedev` (Standard LRS, TLS 1.2 minimum, HTTPS-only, blob versioning on,
30-day delete retention, `prevent_destroy` lifecycle guard) and the private container
`ecommerceprojectdev-tfstate`. Names are derived from the module's `project_name`, `environment` and `location`
variables, which default to `ecommerceproject` / `dev` / `West Europe`.

`env/dev` consumes it through this backend block in `env/dev/backend.tf`:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "ecommerceprojectdev-rg"
    storage_account_name = "ecommerceprojectstatedev"
    container_name       = "ecommerceprojectdev-tfstate"
    key                  = "dev.terraform.tfstate"
  }
}
```

The backing store must exist before `terraform init` in `env/dev` can succeed, so apply `backend/` first. It
keeps its own local state — that is the usual bootstrap trade-off, since it cannot store state in a container it
has not created yet. Blob leases give the state file locking, so concurrent applies are safe. Stage and prod
should follow the same pattern with distinct `key` values (or their own containers) once those environments are
built out.

If you have an older local `env/dev/terraform.tfstate` from before the backend was configured, `terraform init`
will offer to copy it into the container — accept, then delete the local copy and its `.backup` (they contain
database credentials in plaintext). Use `terraform init -migrate-state` if the prompt does not appear.

## Traffic flow

1. `helm_release.alb_controller` installs the ALB controller chart from
   `oci://mcr.microsoft.com/application-lb/charts/alb-controller` (v1.7.9) into `azure-alb-system`, wired to the
   user-assigned identity's client ID.
2. `helm_release.shared_gateway` installs the `ecommerce-app` chart, which renders a single **Gateway** named
   `shared-gateway` with `gatewayClassName: azure-alb-external`, an HTTP listener on port 80, and
   `allowedRoutes.namespaces.from: Same`. Terraform injects the AGC ID and frontend name as the
   `alb.networking.azure.io/alb-id` and `alb.networking.azure.io/alb-frontend` annotations.
3. Each app chart renders an **HTTPRoute** with `parentRefs: [{ name: shared-gateway, sectionName: http }]`,
   empty `hostnames` (so the AGC FQDN matches), and a `PathPrefix` match — `/frontend`, `/auth`, `/product`,
   `/order`, `/payment` — pointing at its own Service.
4. All five app releases `depends_on` the shared gateway, so the Gateway exists before any route attaches.

The public entry point is the AGC frontend FQDN, exposed as the `agc_frontend_fqdn` output:

```bash
terraform -chdir=env/dev output agc_frontend_fqdn
```

## Deploying to Azure

Prerequisites: Azure CLI (logged in, subscription selected), Terraform ≥ 1.5, kubectl, Helm 3, Docker, and an
SSH public key at `~/.ssh/id_rsa.pub` (the jump VM references it directly).

```bash
# 1. remote state backing store — required once, before env/dev can init
cd backend && terraform init && terraform apply

# 2. dev environment — infra + charts in one apply
cd env/dev
# author terraform.tfvars from the table below — it is gitignored and not in the repo
terraform init          # reads backend.tf and connects to the azurerm state container
terraform plan
terraform apply

# 3. cluster access (the aks module also does this via local-exec)
az aks get-credentials -g ecommerce-dev-rg -n ecommerce-aks-cluster --overwrite-existing

# 4. verify
kubectl get pods,svc,httproute -n ecommerce-app
kubectl get gateway shared-gateway -n ecommerce-app -o wide
terraform output agc_frontend_fqdn
```

`terraform.tfvars` is gitignored and is **not** committed — you must supply your own. Required values:

| Variable | Example |
|---|---|
| `resource_group_name` | `ecommerce-dev-rg` |
| `location` | `West Europe` |
| `project_name` / `environment` | `ecommerce` / `dev` |
| `address_space` | `["10.0.0.0/16"]` |
| `subnet_prefixes` | map with keys `web`, `app`, `database`, `aks`, `agc` |
| `acr_name` | `ecommerceacrdevmicroservices` (globally unique) |
| `aks_cluster_name` | `ecommerceaksdevmicroservices` |
| `admin_username` / `admin_password` | Postgres admin credentials (sensitive) |
| `db_host` / `db_name` / `db_user` / `db_password` | e.g. `ecommerce-db-2.postgres.database.azure.com`, `ecommerce-database` |
| `vm_admin_name` / `vm_admin_password` | jump VM credentials (sensitive) |

`db_host` must match the Flexible Server name the database module creates, since the app secret is populated
from the variable rather than the resource output.

### Charts outside Terraform

The charts can also be driven directly, which is faster when iterating on app changes:

```bash
helm upgrade --install ecommerce-helm-product ./helm/apps-product-service -n ecommerce-app
helm upgrade --install shared-gateway ./helm/ecommerce-app -n ecommerce-app \
  --set gateway.enabled=true \
  --set gateway.name=shared-gateway \
  --set gateway.agcID="$AGC_ID" \
  --set gateway.frontendName="$AGC_FRONTEND_NAME"
```

Terraform release names carry iteration suffixes (`ecommerce-helm-product-9`, `ecommerce-helm-auth-7`, …); keep
them in sync if you mix both approaches, or Helm and Terraform will fight over ownership.

## Building and pushing images

Charts pull from `ecommerceacrdevmicroservices.azurecr.io/apps-<service>` with tag `latest` (product) or
`latest-2` (all others). ACR is Premium with a private endpoint, so pushes must originate from a network that
can resolve `privatelink.azurecr.io` — the jump VM in the web subnet, or your own machine with public network
access temporarily enabled.

```bash
az acr login --name ecommerceacrdevmicroservices
REG=ecommerceacrdevmicroservices.azurecr.io

for svc in auth-service product-service order-service payment-service frontend; do
  docker build -t $REG/apps-$svc:latest-2 apps/$svc
  docker push  $REG/apps-$svc:latest-2
done
```

Then bump `image.tag` in the relevant `helm/apps-*/values.yaml` and re-apply. Because the tags are mutable,
prefer immutable tags (git SHA) for anything beyond dev.
