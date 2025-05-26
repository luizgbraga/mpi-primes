#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <mpi.h>

int primo(long int n) {
    long int i;
    
    if (n <= 1) return 0;
    if (n == 2) return 1;
    if (n % 2 == 0) return 0;
    
    for (i = 3; i < (int)(sqrt(n) + 1); i += 2)
        if ((n % i) == 0)
            return 0;
    
    return 1;
}

int main(int argc, char *argv[]) {
    int rank, num_procs;
    int total_local = 0, total_global = 0;
    long int i, n;
    double inicio, fim;
    
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &num_procs);
    
    if (argc < 2) {
        if (rank == 0) {
            printf("Valor invalido! Entre com o valor do maior inteiro\n");
        }
        MPI_Finalize();
        return 0;
    }
    
    n = strtol(argv[1], (char **) NULL, 10);
    
    MPI_Barrier(MPI_COMM_WORLD);
    inicio = MPI_Wtime();
    
    // Cada processo verifica números ímpares com salto de (num_procs * 2)
    // Processo 0 verifica: 3, 3+(num_procs*2), 3+(num_procs*2)*2, ...
    // Processo 1 verifica: 5, 5+(num_procs*2), 5+(num_procs*2)*2, ...
    // etc.
    
    long int inicio_proc = 3 + (rank * 2);
    long int salto = num_procs * 2;
    
    for (i = inicio_proc; i <= n; i += salto) {
        if (primo(i) == 1) {
            total_local++;
        }
    }
    
    MPI_Reduce(&total_local, &total_global, 1, MPI_INT, MPI_SUM, 0, MPI_COMM_WORLD);
    
    MPI_Barrier(MPI_COMM_WORLD);
    fim = MPI_Wtime();
    
    if (rank == 0) {
        total_global += 1; // 2 é primo
        printf("Versao 1 - Procs: %d\n", num_procs);
        printf("Quant. de primos entre 1 e %ld: %d\n", n, total_global);
        printf("Tempo: %.4f segundos\n", fim - inicio);
    }
    
    MPI_Finalize();
    return 0;
}