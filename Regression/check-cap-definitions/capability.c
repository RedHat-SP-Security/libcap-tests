#include <stdio.h>
#include <stdlib.h>
#include <sys/capability.h>



int main(int argc, char *argv[])
{
    int exit_code = 0;
    #ifndef CAP_BPF
        fprintf(stderr,"Macro CAP_BPF is undefined\n");
        exit_code = 1;
    #else
        printf("Macro CAP_BPF is defined\n");
    #endif

    #ifndef CAP_PERFMON
        fprintf(stderr,"Macro CAP_PERFMON is undefined\n");
        exit_code = 1;
    #else
        printf("Macro CAP_PERFMON is defined\n");
    #endif

    #ifndef CAP_CHECKPOINT_RESTORE
        fprintf(stderr,"Macro CAP_CHECKPOINT_RESTORE is undefined\n");
        exit_code = 1;
    #else
        printf("Macro CAP_CHECKPOINT_RESTORE is defined\n");
    #endif

    exit(exit_code);
}