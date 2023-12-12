# Intel SGX SDK

The Intel SGX SDK is one of the oldest SGX runtimes. To allow a holistic analysis of the vulnerability landscape of this runtime, we provide scripts that can compile this single example code for many of the older release versions.

This example was copied from https://github.com/intel/linux-sgx/tree/sgx_2.18.1/SampleCode/Cxx17SGXDemo

The  code contains a single simple ECALL that blindly dereferences a pointer without checking and prints its contents (assuming it is a string).

## Automated build scripts for Intel SDK versions

The script `build_and_run_intel_in_docker.sh` generates a bin folder with the following:

  1. enclave.dump
  2. enclave.json
  3. ptrace.log

It does so for all tagged sgx versions from 2.18.1 down to 2.16, using the docker containers fritzalder/intel-sgx:VERSION to build this directory.
