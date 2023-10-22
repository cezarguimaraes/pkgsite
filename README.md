# pkgsite

## Installing

```bash
helm repo add pkgsite https://cezarguimaraes.github.io/pkgsite
helm install pkgsite pkgsite/pkgsite
```

## Getting started

These steps will walk you through setting up a fully featured _pkgsite_, including a _go module proxy_ able to retrieve private Go packages hosted on Github.

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

        Note the [`.athens-proxy.downloadMode`](https://docs.gomods.io/configuration/download/) property. This example configures _athens-proxy_ to serve private packages from `github.com/YOURORGANIZATION/*` while redirecting any other package to Go's [default module mirror](https://proxy.golang.org/).
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


## Uninstalling

1. Uninstall the release

    ```bash
    helm uninstall pkgsite
    ```
2. Cleanup _Persistent Volume Claims_

    ```bash
    kukectl delete pvc -l app.kubernetes.io/instance=pkgsite

    ```
