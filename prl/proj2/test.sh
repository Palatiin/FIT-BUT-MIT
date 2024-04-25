#!/bin/bash

# Author: Matus Remen (xremen01@stud.fit.vutbr.cz)
# Usage: ./test.sh <input_file> <num_of_iterations>

case "$(uname -s)" in
	Darwin*)
		# Intel Mac
		_MPI_COMPILE_FLAGS=-fopenmp
		_MPI_RUN_FLAGS=
		_PROC_UPPER_BOUND=$(sysctl -n hw.physicalcpu)
		_PROC_LOWER_BOUND=1
		;;
	*)
		# Merlin
		_MPI_COMPILE_FLAGS="--prefix /usr/local/share/OpenMPI"
		_MPI_RUN_FLAGS="--prefix /usr/local/share/OpenMPI"
		_PROC_UPPER_BOUND=12
		_PROC_LOWER_BOUND=1
		;;
esac

# compile
mpic++ $_MPI_COMPILE_FLAGS -o life life.cpp

# calculate number of processes
rows=$(grep -c "" "$1")
proc=$(python3 -c "from math import ceil, sqrt; print(min(max(ceil(sqrt($rows)), $_PROC_LOWER_BOUND), $_PROC_UPPER_BOUND))")

# run
mpirun $_MPI_RUN_FLAGS -np $proc life $1 $2

# cleanup
rm -f life

