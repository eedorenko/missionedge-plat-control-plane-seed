#!/bin/bash
set -eo pipefail

show_usage() {
  echo -e 'Usage:'
  echo "$0 [--gitops-owner <gitops_owner>] [--gitops-repo <gitops_repo>] \\"
  echo " [--storage-account-rg <storage_account_rg>] [--storage-account-name <storage_account_name>] \\"
  echo " [--names <names of cluster or apps>] [--scope <cluster/application>] [--container-registry <container_registry>] \\"
  echo " [--app-workspace <app workspace>] [--app-env <app environment>] [--version <zarf tarball version>]"
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
  echo ' --names                        : Comma separated names. If set to "all" and scope is clusters, it will package and upload for all clusters.'
  echo '                                  If set to "all" and scope is applications, it will package and upload all apps under' 
  echo '                                  the workspace and environment provided'
  echo '                                  Required'
  echo ' --scope                        : Scope of Zarf package. Either "application" or "cluster". Defaults to "cluster"'
  echo '                                  Optional'
  echo '                                  Default: cluster'
  echo ' --app-workspace                : Workspace of App'
  echo '                                  Required if scope is application'
  echo ' --app-env                      : Environment of App'
  echo '                                  Optional'
  echo '                                  Default: production'
  echo ' --version                      : Zarf tarball version'
  echo '                                  Optional'
  echo ' --container-registry           : Container Registry URL'
  echo '                                  Required'
  echo ' --container-registry-username  : Username for the Container Registry'
  echo '                                  Required'
  echo ' --container-registry-secret    : Secret or Password associated with Container Registry'
  echo '                                  Required'
}

SCOPE="cluster"
APP_ENVIRONMENT="production"
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
    --names)
      NAMES=$2
      shift 2
      ;;   
    --scope)
      SCOPE=$2
      shift 2
      ;;
    --app-workspace)
      APP_WORKSPACE=$2
      shift 2
      ;;
    --app-env)
      APP_ENVIRONMENT=$2
      shift 2
      ;;
    --version)
      VERSION=$2
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

validate_inputs () {
    if [[ "${SCOPE}" != "cluster" && "${SCOPE}" != "application" ]]; then
            echo "Error - Invalid scope input: ${SCOPE}" 
            echo "Acceptable values for scope: [cluster,application]"
            exit 1
          fi

    if [[ "${SCOPE}" == "application" && -z "${APP_WORKSPACE}" ]]; then
      echo "Error - App workspace is required for application scope. Add option --app-workspace <app workspace>"
      exit 1
    fi
}

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
    local name=$1
    if [ -n "$VERSION" ]; then
      tar_basename="${tar_basename%.tar.zst}-${VERSION}.tar.zst"
    fi 
    echo "Uploading Tar file ${name}/${tar_basename} to Storage Account"
    az storage blob upload -f ${zarf_tar_file_path} -c ${storage_container_name} -n "${name}/${tar_basename}" --overwrite true
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
    local dir=$1
    if [ -d "${dir}" ]; then
        echo "Found directory ${dir}."
    else
        echo "Directory ${dir} does not exist."
        exit 1
    fi
}
check_if_zarf_exists () {
    if [ -f "zarf.yaml" ]; then
        echo "Found zarf file."
    else
        echo "Zarf file does not exist in $1."
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



package () {
    local zarf_directory=$1
    check_if_dir_exists $zarf_directory
    pushd $zarf_directory > /dev/null
    check_if_zarf_exists $zarf_directory
    package_zarf
    popd > /dev/null
}

upload () {
    local zarf_directory=$1
    local name=$2
    pushd $zarf_directory > /dev/null
    upload_to_storage_account $name
    popd > /dev/null
}

parse_all_names () {
    local -n result=$1
    local trimed_names="$(echo -e "${NAMES}" | tr -d '[:space:]')"
    if [[ "${NAMES}" == "all" ]]; then
        result=(`ls`)
        echo "Packaging for all applications: ${result[@]}"
    else
        #stores each comma separated name to an array
        IFS=',' read -ra result <<< "${NAMES}"
    fi
}

package_and_upload_app () {  
    local scope_dir="applications"
    pushd ${GIT_OPS_REPO}/${scope_dir}/${APP_WORKSPACE}/ApplicationRegistrations > /dev/null
    local names_array
    parse_all_names names_array
    for app_name in "${names_array[@]}"
    do
        local app_dir="${app_name}/${APP_ENVIRONMENT}"                 
        package "$app_dir"
        # iterate over all clusters containing this app
        for cluster in `find ../../../clusters -wholename "*${APP_WORKSPACE}/ApplicationRegistrations/${app_name}*" -exec expr {} : '..\/..\/..\/clusters\/\([^\/]*\)' \; | sort -u`; 
        do
          # upload the app package to the cluster folder in Azure storage
          upload "$app_dir" "$cluster"
        done
    done
    popd > /dev/null
}

package_and_upload_clusters () {
    local scope_dir="clusters"
    pushd ${GIT_OPS_REPO}/${scope_dir} > /dev/null
    local names_array
    parse_all_names names_array
    for cluster_name in "${names_array[@]}"
    do
        package "$cluster_name"
        upload "$cluster_name" "$cluster_name"
    done
    popd > /dev/null
}

clean_up () {
  rm -rf ${GIT_OPS_REPO}
} 

validate_inputs
clone_gitops_repo
login_container_registry
set_storage_account_connection_string
create_blob_container
if [[ "${SCOPE}" == "cluster" ]]; then
    package_and_upload_clusters
else
    package_and_upload_app 
fi
clean_up
echo "Done!"
