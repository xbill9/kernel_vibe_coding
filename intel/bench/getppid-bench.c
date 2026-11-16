/* Cost of an empty system call: 5 million getppid() calls, ns per call.
   Build: gcc -O2 -o getppid-bench getppid-bench.c */
#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <sys/syscall.h>
int main(void){struct timespec a,b;long n=5000000;
clock_gettime(CLOCK_MONOTONIC,&a);for(long i=0;i<n;i++)syscall(SYS_getppid);clock_gettime(CLOCK_MONOTONIC,&b);
printf("getppid: %.1f ns/call\n",((b.tv_sec-a.tv_sec)*1e9+(b.tv_nsec-a.tv_nsec))/n);return 0;}
