#!/bin/bash
set -eo pipefail

show_usage() {
  echo -e 'Usage:'
  echo "$0 [--gitops-owner <gitops_owner>] [--gitops-repo <gitops_repo>] \\"
  echo " [--storage-account-rg <storage_account_rg>] [--storage-account-name <storage_account_name>] \\"
  echo " [--clusters <clusters>] [--tar-version <tar_version>] [--version-overwrite <true/false>] \\"
  echo " [--iron-bank-username <iron_bank_username>] [--iron-bank-cli-secret <iron_bank_cli_secret>]"
  echo ' '
  echo ' Pre-requisites '
  echo '  - Make sure you are logged in to az cli and subscription is set to where storage account lives.'
  echo '  - User logged in needs to have permission to upload to the Storage Account.'
  echo ' '
  echo ' Arguments '
  echo ' '
  echo ' --gitops-owner        : Git Ops Repository Owner'
  echo '                          Required'
  echo ' --gitops-repo         : Git Ops Repository'
  echo '                          Required'
  echo ' --storage-account-rg   : Resource Group for the Storage Account'
  echo '                          Required'
  echo ' --storage-account-name : Existing Storage Account to deploy to'
  echo '                          Required'
  echo ' --clusters             : Comma separated clusters. If set to "all", it will package and upload for all clusters'
  echo '                          Required'
  echo ' --tar-version          : Version of the packaged tar. This also creates a directory in Storage Account'
  echo '                          Required'
  echo ' --version-overwrite    : Flag for overriding the version. If "false", script will fail when uploading an existing version'
  echo '                          Optional'
  echo '                          Default: false'
  echo ' --iron-bank-username   : User name for the Iron Bank repository'
  echo '                          Required'
  echo ' --iron-bank-cli-secret : CLI Secret associated with the user name'
  echo '                          Required'
}

VERSION_OVERWRITE="false"
while (( $# )); do
  case "$1" in
    -h|--help)
      show_usage
      exit 0
      ;;
    --git-ops-owner)
      GIT_OPS_OWNER=$2
      shift 2
      ;;
    --git-ops-repo)
      GIT_OPS_REPO=$2
      shift 2
      ;;   
    --storage-account-rg)
      STORAGE_ACCOUNT_RESOURCE_GROUP=$2
      shift 2
      ;;  
    --storage-account-name)
      STORAGE_ACCOUNT_NAME=$2
      shift 2
      ;;
    --clusters)
      CLUSTER_NAMES=$2
      shift 2
      ;;    
    --tar-version)
      VERSION=$2
      shift 2
      ;;
    --version-overwrite)
      VERSION_OVERWRITE=$2
      shift 2
      ;;  
    --iron-bank-username)
      IRONBANK_USERNAME=$2
      shift 2
      ;;  
    --iron-bank-cli-secret)
      IRONBANK_CLI_SECRET=$2
      shift 2
      ;;  
    --)
      shift
      break
      ;;
    -*|--*)
      echo -e "Unsupported flag $1\n" >&2
      show_usage
      exit 1
      ;;
    *)
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

clone_gitops_repo () {
    echo "Cloning git ops repo"
    git clone https://github.com/${GIT_OPS_OWNER}/${GIT_OPS_REPO}.git
}

set_storage_account_connection_string () {
    export AZURE_STORAGE_CONNECTION_STRING=$(az storage account show-connection-string -g $STORAGE_ACCOUNT_RESOURCE_GROUP  -n $STORAGE_ACCOUNT_NAME -o tsv)
}

package_zarf () {
    echo "Packaging Zarf..."
    zarf package create --confirm
    echo "Done Packing."
}

upload_to_storage_account () {
    local zarf_tar_file_path=$(find . -name "*.tar.zst")
    local tar_basename=$(basename ${zarf_tar_file_path})
    local storage_container_name="zarf-container"
    echo "Uploading Tar file ${tar_basename} to Storage Account"
    az storage blob upload -f ${zarf_tar_file_path} -c ${storage_container_name} -n "${VERSION}/${tar_basename}" --overwrite ${VERSION_OVERWRITE}
    rm ${zarf_tar_file_path}
}

login_iron_bank () {
    local ironbank_registry="registry1.dso.mil"  
    echo "Logging in to Iron Bank Registry ${ironbank_registry} ..."
    zarf tools registry login ${ironbank_registry} -u ${IRONBANK_USERNAME} -p ${IRONBANK_CLI_SECRET}
}

create_blob_container () {
    local storage_container_name="zarf-container"
    echo "Creating Blob Container (if necessary)..."
    az storage container create -n ${storage_container_name}
}

check_if_dir_exists () {
    local cluster=$1
    if [ -d "${cluster}" ]; then
        echo "Found cluster ${cluster}."
    else
        echo "Cluster ${cluster} does not exist."
        exit 1
    fi
}

check_if_zarf_exists () {
    local cluster=$1
    if [ -f "${cluster}/zarf.yaml" ]; then
        echo "Found zarf file."
    else
        echo "Zarf file does not exist for ${cluster}."
        exit 1
    fi
}

package_and_upload () {
    local cluster_dir="clusters"
    pushd ${GIT_OPS_REPO}/${cluster_dir} > /dev/null

    local trimed_cluster_names="$(echo -e "${CLUSTER_NAMES}" | tr -d '[:space:]')"
    if [[ "${trimed_cluster_names}" == "all" ]]; then
        clusters=(`ls`)
        echo "Packaging For All Clusters: ${clusters[@]}"
    else
        IFS=',' read -ra clusters <<< "${trimed_cluster_names}"
    fi

    for cluster in "${clusters[@]}"
    do
        check_if_dir_exists $cluster
        check_if_zarf_exists $cluster
        pushd $cluster > /dev/null
        package_zarf
        upload_to_storage_account
        popd > /dev/null
    done
    popd > /dev/null
}

clean_up () {
  rm -rf ${GIT_OPS_REPO}
} 

clone_gitops_repo
login_iron_bank
set_storage_account_connection_string
create_blob_container
package_and_upload
clean_up
echo "Done!"