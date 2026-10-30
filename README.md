# cozy-apps

External applications catalog for [Cozystack](https://cozystack.io), built on the structure of [cozystack/external-apps-example](https://github.com/cozystack/external-apps-example). Add this repo to your cluster to get extra apps in the Cozystack dashboard.

Currently provides a managed [Vaultwarden](https://github.com/dani-garcia/vaultwarden) password manager, compatible with Bitwarden clients.

## Installation

1. Push this repository to a Git server your cluster can reach.
2. Set `spec.url` (and `spec.ref.branch` if needed) of the `GitRepository` in `init.yaml` to that repository.
3. Apply it:

```bash
kubectl apply --filename init.yaml
```

This creates a FluxCD `GitRepository` source and a `HelmRelease` that deploys the platform chart. The platform chart registers all available apps via `ApplicationDefinition` CRDs, so they appear in the Cozystack dashboard automatically.

The resources are named `cozy-apps`, so this catalog can run next to `external-apps-example`.

## Available Apps

| App | Kind | Description |
| --- | --- | --- |
| vaultwarden | `Vaultwarden` | Bitwarden-compatible password manager with persistent storage, HTTPS on the tenant domain, and a generated admin token |

Vaultwarden needs no operator: the app chart deploys it directly. On the tenant it uses the ingress class (or Gateway), the domain, and the cert-manager issuer that Cozystack provides.

## Example

Create a Vaultwarden instance (see `examples/vaultwarden.yaml`):

```yaml
apiVersion: apps.cozystack.io/v1alpha1
kind: Vaultwarden
metadata:
  name: passwords
  namespace: tenant-root
spec:
  size: 2Gi
  signupsAllowed: false
  signupsDomainsWhitelist:
    - example.org
  smtp:
    host: smtp.example.org
    security: starttls
    from: vaultwarden@example.org
    username: vaultwarden@example.org
    password: change-me
```

It is served at `https://vaultwarden-passwords.<tenant host>`. The URL and the admin panel token are in the `vaultwarden-passwords-credentials` secret, which the dashboard shows. To create the first user, see [the app README](packages/apps/vaultwarden/README.md#getting-started).

## Repository Structure

```text
init.yaml                          # Bootstrap manifest (GitRepository + HelmRelease)
packages/
  core/platform/                   # Platform chart: HelmCharts and ApplicationDefinitions
  apps/vaultwarden/                # Helm chart deploying Vaultwarden
scripts/
  package.mk                       # Shared Makefile targets for the charts
  update-appdef.sh                 # Syncs generated chart schemas into the ApplicationDefinitions
examples/
  vaultwarden.yaml                 # Vaultwarden instance example
```

## Development

Chart parameter schemas and docs are generated from annotations in each chart's `values.yaml` with [cozyvalues-gen](https://github.com/cozystack/cozyvalues-gen), the same tool the main Cozystack repository uses. `update-appdef.sh` also needs [yq](https://github.com/mikefarah/yq) and `jq`. After editing a chart's `values.yaml`, regenerate the derived files and commit the full diff:

```bash
make -C packages/apps/vaultwarden generate
```

Each `generate` run rewrites the chart's `values.schema.json` and the `## Parameters` section of its `README.md`. It then syncs the schema into the matching `ApplicationDefinition` (`spec.application.openAPISchema` and `spec.dashboard.keysOrder`) in `packages/core/platform/templates/cozyrds.yaml`.

To update Vaultwarden, bump `appVersion` in `packages/apps/vaultwarden/Chart.yaml`. The image tag is taken from it.
