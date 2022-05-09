script_path=`dirname $(readlink -f $0)`
manifest_components_filename=manifest_components.yaml
app_components_filename=app_components.yaml

# render_zarf_file CLUSTER_NAME
render_zarf_file() {
   sed 's#{CLUSTER_NAME}#'$1'#g' $script_path/templates/zarf-header.yaml > zarf.yaml
   if [ -f $manifest_components_filename ]; then
    cat $manifest_components_filename >> zarf.yaml
   fi
   if [ -f $app_components_filename ]; then
    cat $app_components_filename >> zarf.yaml
   fi
}

# add_component COMPONENT_NAME COMPONENT_PATH COMPONENT_FILE
add_component() {
   sed 's#{COMPONENT_NAME}#'$1'#g; s#{COMPONENT_PATH}#'$2'#g' $script_path/templates/zarf-component.yaml >> $3
}

# compose_cluster CLUSTER_NAME
compose_cluster() {
   cluster_name=$1
   root_cluster_folder=./clusters/$cluster_name
   flux_system_kustomization=./flux-system/kustomization.yaml

   cd $root_cluster_folder
   touch $manifest_components_filename
   touch $app_components_filename

   for app in `find . -name kustomization.yaml -not -path $flux_system_kustomization `; do
      ws_name=$(echo $app | cut -d/ -f2) 
      app_type=$(echo $app | cut -d/ -f3) 
      app_name=$(echo $app | cut -d/ -f4) 

      app_path=../../applications/$ws_name/$app_type/$app_name

      if [ $app_type == 'ApplicationRegistrations' ]
      then
          app_target=$(echo $app | cut -d/ -f5)
          app_path=$app_path/$app_target
      fi 

      if [ -f $app_path/zarf.yaml ]; then
        if [ $app_type == 'ManifestDeployments' ]; then
          add_component $app_name $app_path $manifest_components_filename
        else
          add_component $app_name $app_path $app_components_filename
        fi
      fi 
   
   done
   
   render_zarf_file $cluster_name
   rm $manifest_components_filename $app_components_filename
   cd -
}

compose_all() {
  for cluster in `find ./clusters -maxdepth 1 -mindepth 1 -type d `; do
     compose_cluster $(basename $cluster)
  done
}

error() {
   echo $1>&2
   usage
   exit 1
}

usage() {
cat <<EOM

Usage:
  zarf-compose.sh GITOPS_REPO_PATH flag

Flags:
  -h, --help                  this info
  -c, --cluster               cluster name
  -a, --all                   compose for all clusters

EOM
}

if [ -z $1 ]
then
  error "No arguments specified"
elif [ $1 == '-h' ] || [ $1 == '--help' ]  
then
  usage
  exit 0
fi

cd $1  

status=$?
if [ $status -ne 0 ] 
then 
  exit $status
fi

if [ -z $2 ]
then
  error "no flag is specified"
elif [ $2 == '-c' ] || [ $2 == '--cluster' ]
then
  cluster_name=$3
  if [ -z $cluster_name ]
  then
    error "Cluster name is unspecified"
  fi
  compose_cluster $cluster_name
elif [ $2 == '-a' ] || [ $2 == '--all' ]
then
  compose_all
else  
  error "invalid option: $*"
fi
