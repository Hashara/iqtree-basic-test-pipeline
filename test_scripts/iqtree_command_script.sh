#!/bin/bash
######## input varibles #################

ncpus=$ARG1
nthreads=$ARG2
nattempt=$ARG3
working_dir=$ARG4
m_option=$ARG5
unique_name=$ARG6
build_directory=$ARG7
type=$ARG8


#######################################

########### load modules ####################
module load eigen/3.3.7
module load openmpi/4.1.5
module load boost/1.84.0
module load llvm/17.0.1

if [ "$type" == "GPU*"  ]; then
  module load cuda/11.4.1
  module load cudnn/8.2.2-cuda11.4
fi



##############################################
# handle data files
data_params="-s ${DATA_DIR}/${ALIGNMENT}"
if [ "${PARITION}" != "false" ] && [ "${TREE}" != "false" ] && [ "${USE_PARTITION}" == "true" ]; then # both partition and tree files are provided
  data_params="-s ${DATA_DIR}/${ALIGNMENT} -p ${data_location}/${PARITION} -te ${data_location}/${TREE}"
elif  [ "${PARITION}" == "false" ] && [ "${TREE}" != "false" ]; then # no partition file is provided
  data_params="-s ${DATA_DIR}/${ALIGNMENT} -te ${data_location}/${TREE}"
elif [ "${PARTITION}" != "false" ] && [ "${TREE}" == "false" ] && [ "${USE_PARTITION}" == "true" ]; then
  data_params="-s ${DATA_DIR}/${ALIGNMENT} -p ${data_location}/${PARTITION}"
fi

##############################################
# handle mset and mrate options
nn_mset_mrate_option=""
mf_mset_mrate_option=""
if [ ${MSET_OPTION} == "NN" ] && [ ${MRATE_OPTION} == "NN" ]; then
  nn_mset_mrate_option="--mset NN --mrate NN"
elif [ ${MSET_OPTION} == "NN" ] ; then
    if [ ${MRATE_OPTION} == "" ]; then
      nn_mset_mrate_option="--mset NN"
    else
      nn_mset_mrate_option="--mset NN --mrate ${MRATE_OPTION}"
      mf_mset_mrate_option="--mrate ${MRATE_OPTION}"
    fi
elif [ ${MRATE_OPTION} == "NN" ]; then
  if [ ${MSET_OPTION} == "" ]; then
    nn_mset_mrate_option="--mrate NN"
  else
    nn_mset_mrate_option="--mset ${MSET_OPTION} --mrate NN"
    mf_mset_mrate_option="--mset ${MSET_OPTION}"
  fi

fi


######
# creating output directory

mkdir -p ${OUTPUT_DIR}/${type}

file_name="${OUTPUT_DIR}/${type}/execution.$unique_name.log"

> $file_name

echo "========================== execution for ${type}, for ${ncpus} number of CPUs and ${nthreads} number of Threads==========================" >> $file_name
prefix_name="${OUTPUT_DIR}/${type}/$unique_name"


# case for type OPENMP, MPI, HYBRID, NN, NN-MPI, NN-HYBRID, GPU, GPU-MPI, GPU-HYBRID
case $type in
  OPENMP)
    test_type="openmp"
    if [ $nthreds -gt 1 ]; then

      /usr/bin/time -v ${BUILD_DIR}/${build_directory}/iqtree2 $data_params -m $m_option -seed 1 $mf_mset_mrate_option ${OTHER_OPTIONS} -redo --prefix $prefix_name -nt $nthreads>> $file_name 2>&1
    else
      /usr/bin/time -v ${BUILD_DIR}/${build_directory}/iqtree2 $data_params -m $m_option -seed 1 $mf_mset_mrate_option ${OTHER_OPTIONS} -redo --prefix $prefix_name >> $file_name 2>&1
    fi

    ;;
  MPI)
    test_type="mpi"
    ;;
  HYBRID)
    test_type="hybrid"
    ;;
  NN)
    test_type="nn"
    ;;
  NN-MPI)
    test_type="nn-mpi"
    ;;
  NN-HYBRID)
    test_type="nn-hybrid"
    ;;
  GPU)
    test_type="gpu"
    ;;
  GPU-MPI)
    test_type="gpu-mpi"
    ;;
  GPU-HYBRID)
    test_type="gpu-hybrid"
    ;;
  *)
    echo "Invalid test type"
    exit 1
    ;;
esac
