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

OUTPUT_DIR=./bin-and-sgxtrace-v041
rm -f enclave0* *ptrace.log enclave.so

# global prep
mkdir -p $OUTPUT_DIR

# First, build the container
echo "------------------------------------------------"
echo "Building docker container"
echo "------------------------------------------------"

docker build --target sdk -t oe-v0.4.1 --network=host  -f ./open-enclave-v041.Dockerfile .

# Then, run it
echo "------------------------------------------------"
echo "Running now ..."
echo "------------------------------------------------"

docker run -v $OUTPUT_DIR:/root -w /root -v ${SGX_TRACE_RESOLVED}:/sgx-tracer --cap-add=SYS_PTRACE --device /dev/isgx -v /var/run/aesmd:/var/run/aesmd -i -t oe-v0.4.1 bash -c "rm -rf /root/* && cp -r /openenclave/samples/helloworld /root && /sgx-tracer/sgx-tracer /root/helloworld/host/helloworldhost /root/helloworld/enc/helloworldenc.signed.so > /root/ptrace.log"; 

echo "------------------------------------------------"
echo "Done!"
echo "------------------------------------------------"

cp $OUTPUT_DIR/helloworld/enc/helloworldenc.so $OUTPUT_DIR/enclave0.so

ls -la $OUTPUT_DIR
