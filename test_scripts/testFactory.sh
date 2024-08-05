#!/bin/bash

nattempt=${NATTEMPT}
execution_file=""
queue="normal"
m_option="${M_OPTION}"


for ((attempt=1; attempt <= $nattempt; attempt +=1 ));
do
  head=true
  while IFS=, read -r type threads cpus time
  do
    if [[ "$head" != "true" ]]; then
  			echo "Type: $type, Threads: $threads, CPUs: $cpus, Time: $time"
                      mem=$((4 * cpus * threads))GB
                      ncpus=$((cpus * threads))
                      unique_name="$M_option$test_type.cpus.$cpus.threads.$threads.attempt.$attempt"
                      mkdir -p ${OUTPUT_DIR}/${type}
                      working_dir="${OUTPUT_DIR}/${type}"
                      cd ${working_dir}
                      ngpu=0
                      test_type=""
                      build_directory=""
  			# switch case for type OPENMP, MPI, HYBRID, NN, NN-MPI, NN-HYBRID, GPU, GPU-MPI, GPU-HYBRID
            			case $type in
            				OPENMP)
            					test_type="openmp"
            					build_directory="build-wompi"
            					;;
            				MPI)
            					test_type="mpi"
            					build_directory="build-mpi"
            					;;
            				HYBRID)
            					test_type="hybrid"
            					build_directory="build-mpi"
            					;;
            				NN)
            					test_type="nn"
            					build_directory="build-nn"
            					;;
            				NN-MPI)
            					test_type="nn-mpi"
            					build_directory="build-nn-mpi"
            					;;
            				NN-HYBRID)
            					test_type="nn-hybrid"
            					build_directory="build-nn-mpi"
            					;;
            				GPU)
            					test_type="gpu"
            					queue="gpuvolta"
            					ncpus=$((cpus * threads * 12))
            					ngpu=$((cpus * threads))
            					build_directory="build-gpu-nn"
            					;;
            				GPU-MPI)
            					test_type="gpu-mpi"
            					queue="gpuvolta"
            					ncpus=$((cpus * threads * 12))
            					ngpu=$((cpus * threads))
            					build_directory="build-gpu-nn-mpi"
            					;;
            				GPU-HYBRID)
            					test_type="gpu-hybrid"
            					queue="gpuvolta"
            					ncpus=$((cpus * threads * 12))
            					ngpu=$((cpus * threads))
            					build_directory="build-gpu-nn-mpi"
            					;;
            				*)
            					echo "Invalid test type"
            					exit 1
            					;;
            			esac

          echo "${TEST_SCRIPTS_DIR}/iqtree_command_script.sh"


      echo "sub -q$queue -Pdx61 -lwalltime=$time,ncpus=$ncpus,mem=$mem,jobfs=20GB,storage=scratch/dx61,wd -N $test_type.cpus.$cpus.threads.$threads -vARG1=$cpus,ARG2=$threads,ARG3=$attempt,ARG4=$working_dir,ARG5=$m_option,ARG6=$unique_name,ARG7=build_directory,ARG8=$type ${TEST_SCRIPTS_DIR}/iqtree_command_script.sh"

      if [ "$queue" == "gpuvolta" ]; then
        qsub -q$queue -Pdx61 -lwalltime=$time,ncpus=$ncpus,ngpus=$ngpu,mem=$mem,jobfs=20GB,storage=scratch/dx61,wd -N $test_type.cpus.$cpus.threads.$threads -vARG1=$cpus,ARG2=$threads,ARG3=$attempt,ARG4=$working_dir,ARG5=$m_option,ARG6=$unique_name,ARG7=$build_directory,ARG8=$type ${TEST_SCRIPTS_DIR}/iqtree_command_script.sh
      else
        qsub -q$queue -Pdx61 -lwalltime=$time,ncpus=$ncpus,mem=$mem,jobfs=20GB,storage=scratch/dx61,wd -N $test_type.cpus.$cpus.threads.$threads -vARG1=$cpus,ARG2=$threads,ARG3=$attempt,ARG4=$working_dir,ARG5=$m_option,ARG6=$unique_name,ARG7=$build_directory,ARG8=$type ${TEST_SCRIPTS_DIR}/iqtree_command_script.sh
      fi
#      break # remove this line to run all the tests
    else
      head=false
    fi
  done < ${CSV_PATH}

done

