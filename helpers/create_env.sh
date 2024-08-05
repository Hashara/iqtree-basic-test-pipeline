#!/bin/bash

# This script is used to create the environment for the test scripts
export WORK_DIR="/scratch/dx61/sa0557/iqtree2/ci-cd"

export IQ_TREE_DIR="${WORK_DIR}/iqtree2"
export DATA_DIR="${WORK_DIR}/data"
export CSV_PATH="${WORK_DIR}/input.csv"
export BUILD_DIR="${WORK_DIR}/builds"
export TEST_SCRIPTS_DIR="${WORK_DIR}/test_scripts"


export OUTPUT_DIR="${WORK_DIR}/output"

mkdir -p $OUTPUT_DIR

#export NATTEMPT=$1 # number of attempts
#export M_OPTION=$2 # MF/TESTMERGEONLY/TESTONLY ....
#export MRATE_OPTION=$3 # -mrate option
#export MSET_OPTION=$4 # -mset option
#export OTHER_OPTIONS=$5 # other options
#
## data files
#export ALIGNMENT=$6
#export PARTITION=$7
#export TREE=$8
#export USE_PARTITION=$9
#
#echo USE_PARTITION
