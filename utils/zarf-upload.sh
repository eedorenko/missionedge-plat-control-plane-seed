#!/bin/bash
set -eo pipefail

show_usage() {
  echo -e 'Usage:'
  echo "$0 [--gitops-owner <gitops_owner>] [--gitops-repo <gitops_repo>] \\"
  echo " [--storage-account-rg <storage_account_rg>] [--storage-account-name <storage_account_name>] \\"
  echo " [--clusters <clusters>] [--container-registry <container_registry>] \\"
  echo " [--container-registry-username <container_registry_username>] [--container-registry-secret <container_registry_secret>]"
  echo ' '
  echo ' Pre-requisites '
  echo '  - Make sure you are logged in to az cli and subscription is set to where storage account lives.'
  echo '  - User logged in needs to have permission to upload to the Storage Account.'
  echo ' '
  echo ' Arguments '
  echo ' '
  echo ' --gitops-owner                 : Git Ops Repository Owner'
  echo '                                  Required'
  echo ' --gitops-repo                  : Git Ops Repository'
  echo '                                  Required'
  echo ' --storage-account-rg           : Resource Group for the Storage Account'
  echo '                                  Required'
  echo ' --storage-account-name         : Existing Storage Account to deploy to'
  echo '                                  Required'
  echo ' --clusters                     : Comma separated clusters. If set to "all", it will package and upload for all clusters'
  echo '                                  Required'
  echo ' --container-registry           : Container Registry URL'
  echo '                                  Required'
  echo ' --container-registry-username  : Username for the Container Registry'
  echo '                                  Required'
  echo ' --container-registry-secret    : Secret or Password associated with Container Registry'
  echo '                                  Required'
}

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
    --container-registry)
      CONTAINER_REGISTRY=$2
      shift 2
      ;;
    --container-registry-username)
      CONTAINER_REGISTRY_USERNAME=$2
      shift 2
      ;;  
    --container-registry-secret)
      CONTAINER_REGISTRY_SECRET=$2
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
    local cluster=$1
    echo "Uploading Tar file ${tar_basename} to Storage Account"
    az storage blob upload -f ${zarf_tar_file_path} -c ${storage_container_name} -n "${cluster}/${tar_basename}" --overwrite true
    rm ${zarf_tar_file_path}
}

login_container_registry () {
    echo "Logging in to Container Registry ${CONTAINER_REGISTRY} ..."
    zarf tools registry login ${CONTAINER_REGISTRY} -u ${CONTAINER_REGISTRY_USERNAME} -p ${CONTAINER_REGISTRY_SECRET}
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

package_zarf () {
    echo "Packaging Zarf. This may take a few minutes."
    local exit_code=0
    zarf package create --confirm &> /dev/null || exit_code=$?
    if [ ${exit_code} -eq 0 ]; then
      echo "Done packaging Zarf."
    else
      echo "Error in packaging Zarf. Please ensure Container Registry Credentials are correct."
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
        upload_to_storage_account $cluster
        popd > /dev/null
    done
    popd > /dev/null
}

clean_up () {
  rm -rf ${GIT_OPS_REPO}
} 

clone_gitops_repo
login_container_registry
set_storage_account_connection_string
create_blob_container
package_and_upload
clean_up
echo "Done!"