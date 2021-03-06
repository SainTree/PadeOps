#!/bin/bash

CWD=`pwd`
export COMPILER_ID=Intel
export FC=/usr/local/tools/mvapich2-intel-2.2/bin/mpif90
export CC=/usr/local/tools/mvapich2-intel-2.2/bin/mpicc
export CXX=/usr/local/tools/mvapich2-intel-2.2/bin/mpic++
export FFTW_PATH=${CWD}/dependencies/fftw-3.3.5
export DECOMP_PATH=${CWD}/dependencies/2decomp_fft
export VTK_IO_PATH=${CWD}/dependencies/Lib_VTK_IO/build
export HDF5_PATH=/usr/local/tools/hdf5-intel-parallel-mvapich2-1.10.0
