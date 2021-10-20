# Introduction

This repository is a Multicloud control plane configuration repo that defines the target environment for an MCP deployment.

As the platform team makes changes to the manifests in this repository, the control plane will deploy changes to the respective environments to keep them in sync with the manifests.

## Getting Started

[Use this template](https://github.com/microsoft/multicloud-control-plane-seed/generate) to create a new repository.

Configure the [transform action](.github/workflows/transform.yaml) with your values
* `GITOPS_REPO`: Update the `env` block in the action to point to your cluster gitops repo
* `GITOPS_PAT`: Create a new GitHub Actions secret that contains a PAT with `repo` scope

As you add project-specific deployment definitions to this repository feel free to delete the placeholder `.gitkeep` files.
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
