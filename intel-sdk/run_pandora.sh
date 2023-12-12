#!/bin/bash

#INTEL_VERSIONS=("sgx_2.18.1" "sgx_2.18" "sgx_2.17.1" "sgx_2.17" "sgx_2.16" "sgx_2.15.1" "sgx_2.15" "sgx_2.14")
#INTEL_VERSIONS=("sgx_2.14")
INTEL_VERSIONS=("sgx_2.17.1" "sgx_2.17" "sgx_2.16" "sgx_2.15.1" "sgx_2.15" "sgx_2.14")

OUTPUT_DIR=./bin-and-sgxtrace

PANDORA_DIR=../../pandora
PANDORA=$PANDORA_DIR/pandora.py
PANDORA_LOG_FOLDER=$PANDORA_DIR/logs/debugging_logs
PANDORA_STEPS=2000

# Print a double check of all versions

echo "------------------------------------------------"
echo " Running pandora on all SDK versions"
echo "------------------------------------------------"
for i in "${INTEL_VERSIONS[@]}"
do
  echo "------------------------------------------------"
  echo -e -n "Enclave version $i.enclave.so:\t| "
  echo $(strings $OUTPUT_DIR/$i.enclave.so | grep SGX_TRTS_VERSION_)
  echo "------------------------------------------------"
  echo "Go go, Pandora..."
  echo "------------------------------------------------"

  # Cleanup
  rm -rf $OUTPUT_DIR/pandora_$i
  rm -rf $PANDORA_LOG_FOLDER

  # Actual run
  $PANDORA run -n $PANDORA_STEPS -c $PANDORA_DIR/config-debugging.ini -s dump --sdk-json-file=$OUTPUT_DIR/$i.enclave.json --sdk-elf-file=$OUTPUT_DIR/$i.enclave.so $OUTPUT_DIR/$i.enclave.dump

  # Copy results
  cp -r $PANDORA_LOG_FOLDER $OUTPUT_DIR/pandora_$i

  echo "------------------------------------------------"
  echo
done

echo
echo "------------------------------------------------"
echo "Done \o/"
echo "------------------------------------------------"
