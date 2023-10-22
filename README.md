# pkgsite

Although [pkg.go.dev](https://pkg.go.dev/) has been [opensourced a few years ago](https://go.dev/blog/pkgsite), self-hosting a fully featured version of pkgsite for private packages is still a cumbersome process. 

This repository provides a Helm chart to:
1. Deploy the pkgsite frontend.
2. Deploy, migrate and seed its PostgreSQL database, powered by the [bitnami/postgresql](https://artifacthub.io/packages/helm/bitnami/postgresql) Chart.
3. Optionally deploy a Redis cluster, used by the frontend to cache rendered pages. Powered by the [bitnami/redis](https://artifacthub.io/packages/helm/bitnami/redis) Chart.
4. Optionally deploy an [athens-proxy](https://github.com/gomods/athens#welcome-to-athens-gophers) instance, in order to provide access to private go modules.

## Installing

```bash
helm repo add pkgsite https://cezarguimaraes.github.io/pkgsite
helm install pkgsite pkgsite/pkgsite
```

## Getting started

These steps will walk you through setting up a fully featured _pkgsite_ deployment, including a _go module proxy_ able to retrieve private Go packages hosted on Github.

1. Create a namespace to contain pkgsite resources.

   ```bash
   kubectl create namespace pkgsite
   ```
2. (Optional) Configure the private go modules proxy
   1. Create a secret to store a GITHUB_TOKEN

       ```bash
       kubectl create secret -n pkgsite generic github-token --from-literal=token=$GITHUB_TOKEN
       ```

    2. Create a _values.yaml_ file to configure the proxy:
  
        ```yaml
        athens-proxy:
          enabled: true
        
          downloadMode: |
            downloadURL = "https://proxy.golang.org"
        
            mode = "redirect"
        
            download "github.com/YOURORGANIZATION/*" {
              mode = "sync"
            }
        
          configEnvVars:
            - name: ATHENS_GONOSUM_PATTERNS
              value: github.com/YOURORGANIZATION/*
            - name: ATHENS_GITHUB_TOKEN
              valueFrom:
                # this secret is expected to exist. Example:
                # kubectl create secret generic github-token --from-literal=token=$GITHUB_TOKEN
                secretKeyRef:
                  name: github-token
                  key: token
            - name: ATHENS_DOWNLOAD_MODE
              valueFrom:
                # this configMap is created by setting athens-proxy.downloadMode
                configMapKeyRef:
                  name: athens-config
                  key: download.hcl
        ```

        Note the [`.athens-proxy.downloadMode`](https://docs.gomods.io/configuration/download/) property. This example configures _athens-proxy_ to serve private packages from `github.com/YOURORGANIZATION/*`, while redirecting any other package to Go's [default module mirror](https://proxy.golang.org/) for improved performance and reduced costs.
3. Install the chart
   1. Using the _values.yaml_ file created on the previous step:
  
      ```bash
      helm install pkgsite pkgsite/pkgsite -f values.yaml -n pkgsite
      ```

    This can take a few minutes as the seed-db post-hook-install seeds the
    pkgsite's database.
4. Verify deployment status

   ```bash
   kubectl get pod -n pkgsite
   NAME                      READY   STATUS      RESTARTS   AGE
   pkgsite-86566fc8b-hfzbs   1/1     Running     0          9m48s
   pkgsite-postgresql-0      1/1     Running     0          9m48s
   pkgsite-redis-master-0    1/1     Running     0          9m48s
   pkgsite-setup-db-snxmb    0/1     Completed   0          9m36s
   ```
5. Browse your docs locally:

   ```bash
   kubectl port-forward svc/pkgsite -n pkgsite 8080
   ```

## Uninstalling

1. Uninstall the release

    ```bash
    helm uninstall pkgsite
    ```
2. Cleanup _Persistent Volume Claims_

    ```bash
    kukectl delete pvc -l app.kubernetes.io/instance=pkgsite
    ```

## Exposing the service

This step will vary according to your cluster's networking. Some options are:

* Update the [serviceType](./helm/values.yaml#71) to LoadBalancer
* Enable and configure an [Ingress resource](./helm/values.yaml#74)
* Configure an ingress using custom networking solutions such as Istio or Consul. Refer to their documentation for instructions.

⚠️ Take care to not expose private go modules documentation to the public internet.

## Advanced configuration

All YAML snippets in this section should be included in your custom _values.yaml_ file.

### Seeded packages

   You can change the list of packages that are seeded when the chart is installed:

   ```yaml
   seed:
     packages:
     - std@latest
     - golang.org/x/tools@latest
     - github.com/YOURORGANIZATION/YOURPACKAGE@all
   ```

   > Note you can seed all versions of a package, including `std`. It can, however, take a long time. Seeding packages is not necessary: users can request that any package be fetched by navigating to `pkgsite.domain/<import-path>[@version]`.

### ReplicaCount, Autoscaling, Service & Ingress

   Find the complete list of deployment settings in the default [_values.yaml_ file](./helm/values.yaml).

### PostgreSQL

   Find the complete list of PostgreSQL settings in the chart's [ArtifactHub page](https://artifacthub.io/packages/helm/bitnami/postgresql#parameters). Prefix parameters by `postgresql`:

   ```yaml
   postgresql:
     image:
       registry: my-private-container-registry.io
   ```

### Redis

   Find the complete list of Redis settings in the chart's [ArtifactHub page](https://artifacthub.io/packages/helm/bitnami/redis#parameters). Prefix parameters by `redis`:

   ```yaml
   redis:
     architecture: replication
   ```

### athens-proxy

   Find the complete list of athens-proxy settings in the chart's [Github Repository](https://github.com/gomods/athens-charts/blob/main/charts/athens-proxy/values.yaml). Prefix parameters by `athens-proxy`:
   
   ```yaml
   athens-proxy:
     storage:
       type: disk
       disk:
         storageRoot: "/var/lib/athens"
         persistence:
           enabled: true
           accessMode: ReadWriteOnce
           size: 4Gi
   ```
