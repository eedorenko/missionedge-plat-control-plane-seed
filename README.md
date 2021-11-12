# Introduction

This repository is a Coral control plane configuration repo that defines the target environment for an MCP deployment.

As the platform team makes changes to the manifests in this repository, the control plane will deploy changes to the respective environments to keep them in sync with the manifests.

If you are unfamiliar with the premise behind the broader solution, please refer to the overview [here](https://github.com/microsoft/coral). This doc will give context to each of the repositories and what's going on "under the hood".
## Getting Started

### Prerequisites

#### Cluster & Flux Installation

This solution assumes that a Kubernetes cluster has been provisioned on your preferred cloud provider (e.g. Azure Kubernetes Service). 

It also assumes that Flux installation/[bootstrapping](https://fluxcd.io/docs/cmd/flux_bootstrap/) is managed outside of this solution.

#### Cluster GitOps Repo & PAT

You'll need to have templated the [Cluster GitOps Seed Repo](https://github.com/microsoft/coral-cluster-gitops-seed) and have a [personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) created with `repo` scope.

### Template this Repo

[Use this template](https://github.com/microsoft/coral-control-plane-seed/generate) to create your new repository.

### Configure the Workflow that runs the Coral CLI

Configure the [transform action](.github/workflows/transform.yaml) with your values
* `GITOPS_REPO`: Update the `env` block in the action to point to your cluster gitops repo
* `GITOPS_PAT`: Create a new GitHub Actions secret that contains a PAT with `repo` scope

A run is triggered after each commit into the repository, so you will see the changes in the Cluster GitOps repo reflected. It's important to follow the next steps in order so that you do not have an error for an orphaned application with no cluster assignment.

### Register Cluster(s)

Add a cluster definition under the `/clusters` directory. You can find the schema for a cluster definition in the `/schemas` directory [here](https://github.com/microsoft/coral-control-plane-seed/tree/main/schemas/Cluster.yaml). 

It's important to note that the values under `labels` are free-form text and not enforced. It is used to help match application assignments but is not validated for any type of ground-truth accuracy.

Once a new cluster is registered in this repo, a new subdirectory will populate in the Cluster GitOps repo. You can point your cluster's Flux instance to the correct `/clusters` subdirectory. 

For example, for a cluster named `cluster-314`, Flux on that cluster would point to the path `clusters/cluster-314`.

### Create workspaces

A coral workspace is a collection of one or more applications. The concept of workspace enable filter and configure access to only an specific group of applications.

Add a `Workspace` file inside the workspaces folder. The schema for the `Workspace.yaml` can be found in the `/schemas` directory [here](https://github.com/microsoft/coral-control-plane-seed/tree/main/schemas/Workspace.yaml).

### Register Application(s)

Add an `ApplicationDeployment` file that points to the application's `app.yaml` file found in one of the application repos (generated from one of the seeds below).

 Repository | Location
-|-
.Net Application Seed | https://github.com/microsoft/coral-template-dotnet
Java Application Seed | https://github.com/microsoft/coral-template-java

The schema for the `ApplicationDeployment.yaml` can be found in the `/schemas` directory [here](https://github.com/microsoft/coral-control-plane-seed/tree/main/schemas/ApplicationDeployment.yaml)

An application needs to be assigned to an specific workspace. A folder with the same name of the workspace must exist inside the `applications` folder. As you add project-specific deployment definitions to this repository feel free to delete the placeholder `.gitkeep` files.

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
