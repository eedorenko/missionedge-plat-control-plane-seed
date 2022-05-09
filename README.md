# Introduction

This is the BigBang control plane seed to get started with deploying applications leveraging the [Coral](https://github.com/microsoft/coral) platform.

## The BigBang Seed

This control plane repo seed is a customized version of the default Coral seed and it deploys specific BigBang services.

The BigBang seed shares the initial setup of the platform as described in [platform setup instructions](https://github.com/microsoft/coral/blob/main/docs/platform-setup.md) in the main Coral repo.

However, since this seed assumes that the neither the UI portal nor the API will be used for management of the platform, neither the AAD nor the Portal UI setup are required. Instead, a workflow in this repo is used to [register a new application with Coral](./docs/application-registration.md), and a workflow in each application's repo is used to [trigger an application refresh](docs/application-refresh.md).

> NOTE
>
> The application registration process requires a `CP_REPO_RENDER_TOKEN` secret registered in the control plane repo. See [Register a new application with Coral](./docs/application-registration.md) for more information.

For more information on other aspects of Coral, please refer to the [Coral documentation](https://github.com/microsoft/coral/tree/main/docs)

## Control Plane Repo Overview

The control plane repo keeps track of information in a set of folders and files, with this strucure:

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

## See Also

- [Register a new application with Coral](./docs/application-registration.md)
- [Triggering an application refresh](application-refresh.md)
- [Coral Documentation](https://github.com/microsoft/coral/tree/main/docs)
