#!/bin/bash

# Batch script generated using NERSC's Batch Script Generator
# Reference: https://iris.nersc.gov/utils/jobscript

#SBATCH -N 1
#SBATCH -C gpu
#SBATCH -G 1
#SBATCH -q regular
#SBATCH -J test_job_1
#SBATCH --mail-user=<USER_EMAIL>
#SBATCH --mail-type=ALL
#SBATCH -A m4402
#SBATCH -t 0:5:0

# OpenMP environment configuration
export OMP_NUM_THREADS=1
export OMP_PLACES=threads
export OMP_PROC_BIND=spread

# Execute the application
srun -n 1 -c 128 --cpu_bind=cores -G 1 --gpu-bind=single:1 eic-opticks
