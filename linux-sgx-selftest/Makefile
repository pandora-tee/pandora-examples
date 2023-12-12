ENCL_CFLAGS := -Wall -Werror -static -nostdlib -nostartfiles -fPIC \
	       -fno-stack-protector -mrdrnd $(INCLUDES)
ENCL_OPT    := -Os

all: linux_test_encl.elf

linux_test_encl.elf: test_encl.lds test_encl.c test_encl_bootstrap.S
	$(CC) $(ENCL_OPT) $(ENCL_CFLAGS) -T $^ -o $@ -Wl,--build-id=none

clean:
	rm -Rf *.o *.elf
