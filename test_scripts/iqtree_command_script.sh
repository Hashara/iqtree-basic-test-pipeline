#!/bin/bash
######## input varibles #################
export WORK_DIR="/scratch/dx61/sa0557/iqtree2/ci-cd"
source ${WORK_DIR}/helpers/create_env.sh
source ${WORK_DIR}/helpers/env.sh

ncpus=$ARG1
nthreads=$ARG2
nattempt=$ARG3
working_dir=$ARG4
m_option=$ARG5
unique_name=$ARG6
build_directory=$ARG7
type=$ARG8

########################################
mkdir -p ${OUTPUT_DIR}/${type}

cd ${OUTPUT_DIR}/${type}

file_name="${OUTPUT_DIR}/${type}/execution.$unique_name.log"

> $file_name

echo "========================== execution for ${type}, for ${ncpus} number of CPUs and ${nthreads} number of Threads==========================" >> $file_name


#######################################

########### load modules ####################
module load eigen/3.3.7
module load openmpi/4.1.5
module load boost/1.84.0
module load llvm/17.0.1

#if [ "$type" == "GPU*"  ]; then
module load cuda/11.4.1
module load cudnn/8.2.2-cuda11.4
#fi



##############################################
# handle data files
data_params="-s ${DATA_DIR}/${ALIGNMENT}"

if [ "${PARITION}" != "false" ] && [ "${TREE}" != "false" ] && [ "${USE_PARTITION}" == true ]; then # both partition and tree files are provided
  data_params="-s ${DATA_DIR}/${ALIGNMENT} -p ${DATA_DIR}/${PARITION} -te ${DATA_DIR}/${TREE}"
elif  [ "${PARITION}" == "false" ] && [ "${TREE}" != "false" ]; then # no partition file is provided
  data_params="-s ${DATA_DIR}/${ALIGNMENT} -te ${DATA_DIR}/${TREE}"
elif [ "${PARTITION}" != "false" ] && [ "${TREE}" == "false" ] && [ "${USE_PARTITION}" == true ]; then
  data_params="-s ${DATA_DIR}/${ALIGNMENT} -p ${DATA_DIR}/${PARTITION}"
fi

##############################################
# handle mset and mrate options
nn_mset_mrate_option=""
mf_mset_mrate_option=""
if [ "${MSET_OPTION}" == "NN" ] && [ "${MRATE_OPTION}" == "NN" ]; then
  nn_mset_mrate_option="--mset NN --mrate NN"
  mf_mset_mrate_option="--mset \"GTR,JC,K2P,F81,HKY,TN\""
elif [ "${MSET_OPTION}" == "NN" ] ; then
    if [ "${MRATE_OPTION}" == "false" ]; then
      nn_mset_mrate_option="--mset NN"
      mf_mset_mrate_option="--mset \"GTR,JC,K2P,F81,HKY,TN\""

    else
      nn_mset_mrate_option="--mset NN --mrate ${MRATE_OPTION}"
      mf_mset_mrate_option="--mrate ${MRATE_OPTION} --mset \"GTR,JC,K2P,F81,HKY,TN\""
    fi
elif [ "${MRATE_OPTION}" == "NN" ]; then
  if [ "${MSET_OPTION}" == "false" ]; then
    nn_mset_mrate_option="--mrate NN"
  else
    nn_mset_mrate_option="--mset ${MSET_OPTION} --mrate NN"
    mf_mset_mrate_option="--mset ${MSET_OPTION}"
  fi

fi

##############################################
other_options=""
if [ "${OTHER_OPTIONS}" != "false" ]; then
  other_options="${OTHER_OPTIONS}"
fi

##############################################
# model dir
model_dir="/scratch/dx61/sa0557/iqtree2/models"
nn_model_finder="${model_dir}/resnet_modelfinder.onnx"
nn_alpha_finder="${model_dir}/lanfear_alpha_lstm.onnx"
nn_models_option="--nn-path-model $nn_model_finder --nn-path-rates $nn_alpha_finder"

######
# creating output directory
mkdir -p ${OUTPUT_DIR}/${type}/$unique_name
prefix_name="${OUTPUT_DIR}/${type}/$unique_name/$unique_name"


# case for type OPENMP, MPI, HYBRID, NN, NN-MPI, NN-HYBRID, GPU, GPU-MPI, GPU-HYBRID
case $type in
  OPENMP)
    test_type="openmp"
    if [ "$nthreads" -gt 1 ]; then

      /usr/bin/time -v ${BUILD_DIR}/${build_directory}/iqtree2 $data_params -m $m_option -seed 1 $mf_mset_mrate_option $other_options -redo --prefix $prefix_name -nt $nthreads>> $file_name 2>&1
    else
      /usr/bin/time -v ${BUILD_DIR}/${build_directory}/iqtree2 $data_params -m $m_option -seed 1 $mf_mset_mrate_option $other_options -redo --prefix $prefix_name >> $file_name 2>&1
    fi

    ;;
  MPI)
    test_type="mpi"
    mpirun -np $ncpus ${BUILD_DIR}/${build_directory}/iqtree2-mpi $data_params -m $m_option -seed 1 $mf_mset_mrate_option $other_options -redo --prefix $prefix_name >> $file_name 2>&1
    ;;
  HYBRID)
    test_type="hybrid"
    export OMP_NUM_THREADS=$nthreads
    export GOMP_CPU_AFFINITY=0-47

    /usr/bin/time -v mpirun -np $ncpus --map-by node:PE=$OMP_NUM_THREADS --rank-by core --report-bindings ${BUILD_DIR}/${build_directory}/iqtree2-mpi $data_params -m $m_option -seed 1 $mf_mset_mrate_option $other_options -redo --prefix $prefix_name -nt $nthreads>> $file_name 2>&1
    ;;
  NN)
    test_type="nn"
    if [ "$nthreads" -gt 1 ]; then
          /usr/bin/time -v ${BUILD_DIR}/${build_directory}/iqtree2 $data_params -m $m_option -seed 1 $nn_mset_mrate_option $other_options $nn_models_option -redo --prefix $prefix_name -nt $nthreads>> $file_name 2>&1
        else
          /usr/bin/time -v ${BUILD_DIR}/${build_directory}/iqtree2 $data_params -m $m_option -seed 1 $nn_mset_mrate_option $other_options $nn_models_option -redo --prefix $prefix_name >> $file_name 2>&1
        fi
    ;;
  NN-MPI)
    test_type="nn-mpi"
    mpirun -np $ncpus ${BUILD_DIR}/${build_directory}/iqtree2-mpi $data_params -m $m_option -seed 1 $nn_mset_mrate_option $other_options $nn_models_option -redo --prefix $prefix_name >> $file_name 2>&1
    ;;
  NN-HYBRID)
    test_type="nn-hybrid"
    export OMP_NUM_THREADS=$nthreads
    export GOMP_CPU_AFFINITY=0-47
    /usr/bin/time -v mpirun -np $ncpus --map-by node:PE=$OMP_NUM_THREADS --rank-by core --report-bindings ${BUILD_DIR}/${build_directory}/iqtree2-mpi $data_params -m $m_option -seed 1 nn_mset_mrate_option $other_options $nn_models_option -redo --prefix $prefix_name -nt $nthreads>> $file_name 2>&1
   ;;
  GPU)
    test_type="gpu"
    if [ "$nthreads" -gt 1 ]; then
        /usr/bin/time -v ${BUILD_DIR}/${build_directory}/iqtree2 $data_params -m $m_option -seed 1 $nn_mset_mrate_option $other_options $nn_models_option -redo --prefix $prefix_name -nt $nthreads>> $file_name 2>&1
      else
        /usr/bin/time -v ${BUILD_DIR}/${build_directory}/iqtree2 $data_params -m $m_option -seed 1 $nn_mset_mrate_option $other_options $nn_models_option -redo --prefix $prefix_name >> $file_name 2>&1
      fi
    ;;
  GPU-MPI)
    test_type="gpu-mpi"
    mpirun -np $ncpus ${BUILD_DIR}/${build_directory}/iqtree2-mpi $data_params -m $m_option -seed 1 $nn_mset_mrate_option $other_options $nn_models_option -redo --prefix $prefix_name >> $file_name 2>&1

    ;;
  GPU-HYBRID)
    test_type="gpu-hybrid"
    export OMP_NUM_THREADS=$nthreads
    export GOMP_CPU_AFFINITY=0-47
    /usr/bin/time -v mpirun -np $ncpus --map-by node:PE=$OMP_NUM_THREADS --rank-by core --report-bindings ${BUILD_DIR}/${build_directory}/iqtree2-mpi $data_params -m $m_option -seed 1 $nn_mset_mrate_option $other_options $nn_models_option -redo --prefix $prefix_name -nt $nthreads>> $file_name 2>&1

    ;;
  *)
    echo "Invalid test type"
    exit 1
    ;;
esac
