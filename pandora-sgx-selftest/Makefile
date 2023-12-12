ENCL_CFLAGS := -Wall -Werror -static -nostdlib -nostartfiles -fPIC -fpie \
	       -fno-stack-protector -mrdrnd $(INCLUDES)
ENCL_OPT    := #-Os
ENCL_FIX    := -DFIX_SANITIZATION=4
EEXIT_FIX   := -DEEXIT_SANITIZATION=2

.PHONY : all clean
all: pandora_selftest_enclave_sanitization pandora_pointer-deref.elf pandora_indirect-jump.elf pandora_selftest_enclave_eexit

pandora_selftest_enclave_sanitization: test_encl.lds test_encl.c test_encl_bootstrap.S
	$(CC) $(ENCL_OPT) $(ENCL_CFLAGS) -DFIX_SANITIZATION=0 -Os $(EEXIT_FIX) -T $^ -o $@0.elf -Wl,--build-id=none
	$(CC) $(ENCL_OPT) $(ENCL_CFLAGS) -DFIX_SANITIZATION=1     $(EEXIT_FIX) -T $^ -o $@1.elf -Wl,--build-id=none
	$(CC) $(ENCL_OPT) $(ENCL_CFLAGS) -DFIX_SANITIZATION=2     $(EEXIT_FIX) -T $^ -o $@2.elf -Wl,--build-id=none
	$(CC) $(ENCL_OPT) $(ENCL_CFLAGS) -DFIX_SANITIZATION=3     $(EEXIT_FIX) -T $^ -o $@3.elf -Wl,--build-id=none
	$(CC) $(ENCL_OPT) $(ENCL_CFLAGS) -DFIX_SANITIZATION=4     $(EEXIT_FIX) -T $^ -o $@4.elf -Wl,--build-id=none

pandora_pointer-deref.elf: test_encl.lds pointer-deref.c test_encl_bootstrap.S
	$(CC) $(ENCL_OPT) $(ENCL_CFLAGS) $(ENCL_FIX) $(EEXIT_FIX) -T $^ -o $@ -Wl,--build-id=none -O0

pandora_indirect-jump.elf: test_encl.lds indirect-jump.c test_encl_bootstrap.S
	$(CC) $(ENCL_OPT) $(ENCL_CFLAGS) $(ENCL_FIX) $(EEXIT_FIX) -T $^ -o $@ -Wl,--build-id=none -O0

pandora_selftest_enclave_eexit: test_encl.lds nop_encl.c test_encl_bootstrap.S
	$(CC) $(ENCL_OPT) $(ENCL_CFLAGS) $(ENCL_FIX) -DEEXIT_SANITIZATION=0 -T $^ -o $@0.elf -Wl,--build-id=none
	$(CC) $(ENCL_OPT) $(ENCL_CFLAGS) $(ENCL_FIX) -DEEXIT_SANITIZATION=1 -T $^ -o $@1.elf -Wl,--build-id=none
	$(CC) $(ENCL_OPT) $(ENCL_CFLAGS) $(ENCL_FIX) -DEEXIT_SANITIZATION=2 -T $^ -o $@2.elf -Wl,--build-id=none

clean:
	rm -Rf *.o *.elf
