#include <stddef.h>
/**
 * Very simple example of an enclave that receives a single
 * pointer and jumps to it.
 * Useful to test untrusted control-flow detection.
*/
void encl_body(int *rdi,  void *rsi)
{
  void *ptr = rdi;
  asm ("jmp *%0\n\t" : "=r" (ptr));
}
