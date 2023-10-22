# pkgsite

## Installing

1. Add the Helm repository

    ```bash
    helm repo add pkgsite https://cezarguimaraes.github.io/pkgsite
    ```
2. Install the chart

    ```bash
    helm install pkgsite pkgsite/pkgsite
    ```

    This can take a few minutes as the seed-db post-hook-install seeds the
    pkgsite's database.

## Uninstalling

1. Uninstall the release

    ```bash
    helm uninstall pkgsite
    ```
2. Cleanup _Persistent Volume Claims_

    ```bash
    kukectl delete pvc -l app.kubernetes.io/instance=pkgsite

    ```
