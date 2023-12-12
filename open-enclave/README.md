# OpenEnclave

OpenEnclave is an enclave shielding runtime. This folder allows to generate an enclave dump with the help of a Docker file for three different versions of OpenEnclave.

## Automated build scripts for OE SDK versions

Normally, you can just (tm) use the scripts like `generate-oe-v060-no-flc.sh` 

## Generating

To generate the Docker containers yourself, you can use the `open-enclave-v*.Dockerfile` and call it like this:

```bash
docker build --target sdk -t oe-v0.6.0 --network=host  -f ./open-enclave-v060.Dockerfile .
```

## Example use (no FLC)

Example use to spawn a shell for v0.6.0 (and have sgx-tracer)

`docker run -v ${SGX_TRACE_RESOLVED}:/sgx-tracer --cap-add=SYS_PTRACE --device /dev/isgx -v /var/run/aesmd:/var/run/aesmd -i -t oe-v0.6.0 bash`
