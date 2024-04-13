#!/bin/bash

case "$(uname -s)" in
	Darwin*)
		_MPI_COMPILE_FLAGS=-fopenmp
		_MPI_RUN_FLAGS=
		;;
	*)
		_MPI_COMPILE_FLAGS="--prefix /usr/local/share/OpenMPI"
		_MPI_RUN_FLAGS="--prefix /usr/local/share/OpenMPI"
		;;
esac

# compile
mpic++ $_MPI_COMPILE_FLAGS -o life life.cpp

# run
mpirun $_MPI_RUN_FLAGS -np 4 life $1 $2

# cleanup
rm -f life

