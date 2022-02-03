# Introduction

This is the default control plane seed to get started with deploying applications via [Coral](https://github.com/microsoft/coral)

## Getting Started

To get started, see the [platform setup instructions](https://github.com/microsoft/coral/blob/main/docs/platform-setup.md) in the main Coral repo.

## Overview

- `.github/workflows` - Runs a workflow on each push to transform Coral entities into cluster gitops repo YAML to be processed by Flux
- `applications`
  - `<workspace-name>`
    - `ApplicationRegistrations` - defines the `ApplicationRegistrations` for a given workspace ([sample](https://github.com/microsoft/coral/blob/main/docs/samples/ApplicationRegistration.yaml))
    - `ManifestDeployments` - defines the `ManifestDeployments` (dialtone services) for a given workspace
- `assignments` - holds the application:cluster assignments after Coral processes the repo
- `clusters` - defines the `Clusters` in your platform ([sample](https://github.com/microsoft/coral/blob/main/docs/samples/Cluster.yaml))
- `manifests` - holds Kubernetes YAML for use with `ManifestDeployments`
- `templates` - defines the available `ApplicationTemplates` in your platform ([sample](https://github.com/microsoft/coral/blob/main/docs/samples/ApplicationTemplate.yaml))
- `workspaces` - defines the `Workspaces` in your platform ([sample](https://github.com/microsoft/coral/blob/main/docs/samples/Workspace.yaml))

## Configure Dialtone Services

### Cluster Logs and Metrics

Fluent Bit is configured to process cluster logs and can be enabled to output logs and metrics to Azure Log Analytics. Additional inputs, outputs, filters, and parsers can be configured by adjusting the Helm chart values and patching the changes. For more information on how to configure, see [Fluent Bit Docs](https://docs.fluentbit.io/manual/). 

To enable Azure Log Analytics for metrics and logs:

1. [Create an Azure Log Analytics workspace](https://docs.microsoft.com/en-us/azure/azure-monitor/logs/quick-create-workspace)
2. Update the values of `workspace_id` and `key` in `manifests/fluentbit/secret.yaml` with your Log Analytics workspace Id and primary or secondary key  
  **WARNING: It is not secure to put theses keys in plain text. A proposed solutions for securing secrets is coming soon**
3. In `applications/coral-system/ManifestDeployments/fluentbit.yaml`, uncomment the `azure-log-analytics` patch
``` yaml
      patches:
        - azure-log-analytics.yaml
``` 
4. Uncomment `- telegraf.yaml` in `manifests/fluentbit/kustomization.yaml`
5. Commit and push the changes to the control-plane
6. Test out a query - *it may take 10-15 minutes for your custom logs and metrics tables to populate in the portal*
  - Navigate to your Log Analytics workspace in the Azure Portal
  - Under "General", click the "Logs" tab
  - Ensure there is a `Custom Logs` table called `clustermetrics_CL` and `clusterlogs_CL`
  - Run the following queries to filter logs and metrics by a Coral workspace:
  
``` SQL
clustermetrics_CL
| where workspace_s == '<your-coral-workspace-name>'
| limit 100
```

``` SQL
clusterlogs_CL
| where workspace_s == '<your-coral-workspace-name>'
| limit 100
```

When Azure Log Analytics are enabled, a Telegraf deployment, namespace, configMap and Fluent Bit service will be deployed to the clusters specified in `applications/coral-system/ManifestDeployments/fluentbit.yaml`. Telegraf is configured to collect all Prometheus metrics and output them to Fluent Bit. Fluent Bit recieves the metrics and outputs them to Log Analytics.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
