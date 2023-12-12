#!/bin/bash

# Assume sgx-trace is a sibling folder of the example folder
SGX_TRACE_DIR="../../sgx-tracer/ptrace/"
SGX_TRACE_RESOLVED=$(readlink -f $SGX_TRACE_DIR)

if stat $SGX_TRACE_DIR/sgx-tracer > /dev/null; then
  echo "Using sgx-tracer @${SGX_TRACE_DIR}"
else
  echo "Cannot stat SGX-tracer @${SGX_TRACE_DIR}. Aborting"
  exit
fi

INTEL_VERSIONS=(
    "sgx_2.19"  
#    "sgx_2.18.1" 
#    "sgx_2.18" 
    "sgx_2.17.1" 
    "sgx_2.17" 
    "sgx_2.16" 
    "sgx_2.15.1"
    "sgx_2.15" 
    "sgx_2.14"
    "sgx_2.13.3"
)

OUTPUT_DIR=./bin-and-sgxtrace
FAILED_RUNS=()
SUCCESS_RUNS=()

# global prep
rm -rf $OUTPUT_DIR/
mkdir -p $OUTPUT_DIR

for i in "${INTEL_VERSIONS[@]}"
do
  echo "------------------------------------------------"
  echo "Building project for Intel SDK Version $i"
  echo "------------------------------------------------"

  make clean

rm -f enclave0* *ptrace.log enclave.so

# Run docker
if docker run -v $(pwd):/root/compile -v ${SGX_TRACE_RESOLVED}:/sgx-tracer -w /root/compile --device /dev/sgx/enclave --device /dev/sgx/provision --cap-add=SYS_PTRACE fritzalder/intel-sdk:${i} /usr/bin/bash -c "LD_LIBRARY_PATH=/opt/intel/sgxpsw/aesm /opt/intel/sgxpsw/aesm/aesm_service --no-daemon & make clean && make all && LD_LIBRARY_PATH=/opt/intel/sgxpsw/aesm/ /sgx-tracer/sgx-tracer ./app > ptrace.log"; then

    # run sgx trace
    echo "Done with sgx trace on ${i}"

    # mv files to subdir
    mv ptrace.log $OUTPUT_DIR/$i.ptrace.log
    mv enclave0.json $OUTPUT_DIR/$i.enclave.json
    mv enclave0.dump $OUTPUT_DIR/$i.enclave.dump
    mv enclave.so $OUTPUT_DIR/$i.enclave.so
    echo "------------------------------------------------"
    echo "Done with $i"
    echo "------------------------------------------------"
    echo ""
    SUCCESS_RUNS+=($i)
  else
    FAILED_RUNS+=($i)
  fi
done

# Print a double check of all versions

echo "------------------------------------------------"
echo "Final check, printing all enclave versions:"
echo "------------------------------------------------"
for i in "${SUCCESS_RUNS[@]}"
do
  echo -e -n "File $i.enclave.so:\t| "
  echo $(strings $OUTPUT_DIR/$i.enclave.so | grep SGX_TRTS_VERSION_)
  echo -e -n "File $i.enclave.dump:\t| "
  if [ -e "$OUTPUT_DIR/$i.enclave.dump" ]; then
    if [ $(xxd -l 4 -p $OUTPUT_DIR/$i.enclave.dump) = 7f454c46 ]; then
      echo "OK"
    else
      echo "ERROR: Dump is broken (ELF header broken)"
      INCORRECT_OUTPUTS+=($i)
    fi
  else
    echo "ERROR: Does not exist!"
    INCORRECT_OUTPUTS+=($i)
  fi

done

for i in "${FAILED_RUNS[@]}"
do
  echo "Run $i failed!"
done

for i in "${INCORRECT_OUTPUTS[@]}"
do
  echo "Run $i had incorrect outputs!"
done

echo "Done \o/"

# clean up after ourselves
make clean
