#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <mpi.h>

#define TASK_SIZE 500000
#define TAG_TASK 1
#define TAG_RESULT 2
#define TAG_FINISH 3

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

int conta_primos_intervalo(long int inicio, long int fim) {
    int count = 0;
    long int i;
    
    if (inicio % 2 == 0) inicio++;
    
    for (i = inicio; i <= fim; i += 2) {
        if (primo(i) == 1) {
            count++;
        }
    }
    
    return count;
}

void master(long int n, int num_procs) {
    int total_primos = 0;
    long int inicio_tarefa = 3;
    long int fim_tarefa;
    int workers_ativos = num_procs - 1;
    int result;
    MPI_Status status;
    
    for (int i = 1; i < num_procs; i++) {
        if (inicio_tarefa <= n) {
            fim_tarefa = inicio_tarefa + TASK_SIZE - 1;
            if (fim_tarefa > n) fim_tarefa = n;
            
            long int tarefa[2] = {inicio_tarefa, fim_tarefa};
            MPI_Send(tarefa, 2, MPI_LONG, i, TAG_TASK, MPI_COMM_WORLD);
            
            inicio_tarefa = fim_tarefa + 1;
            if (inicio_tarefa % 2 == 0) inicio_tarefa++;
        } else {
            MPI_Send(NULL, 0, MPI_LONG, i, TAG_FINISH, MPI_COMM_WORLD);
            workers_ativos--;
        }
    }
    
    while (workers_ativos > 0) {
        MPI_Recv(&result, 1, MPI_INT, MPI_ANY_SOURCE, TAG_RESULT, MPI_COMM_WORLD, &status);
        total_primos += result;
        
        int worker_id = status.MPI_SOURCE;
        
        if (inicio_tarefa <= n) {
            fim_tarefa = inicio_tarefa + TASK_SIZE - 1;
            if (fim_tarefa > n) fim_tarefa = n;
            
            long int tarefa[2] = {inicio_tarefa, fim_tarefa};
            MPI_Send(tarefa, 2, MPI_LONG, worker_id, TAG_TASK, MPI_COMM_WORLD);
            
            inicio_tarefa = fim_tarefa + 1;
            if (inicio_tarefa % 2 == 0) inicio_tarefa++;
        } else {
            MPI_Send(NULL, 0, MPI_LONG, worker_id, TAG_FINISH, MPI_COMM_WORLD);
            workers_ativos--;
        }
    }
    
    total_primos += 1; // 2 é primo
    printf("Versao 2 - Procs: %d\n", num_procs);
    printf("Quant. de primos entre 1 e %ld: %d\n", n, total_primos);
}

void worker() {
    long int tarefa[2];
    int result;
    MPI_Status status;
    
    while (1) {
        MPI_Recv(tarefa, 2, MPI_LONG, 0, MPI_ANY_TAG, MPI_COMM_WORLD, &status);
        
        if (status.MPI_TAG == TAG_FINISH) {
            break;
        }
        
        result = conta_primos_intervalo(tarefa[0], tarefa[1]);
        MPI_Send(&result, 1, MPI_INT, 0, TAG_RESULT, MPI_COMM_WORLD);
    }
}

int main(int argc, char *argv[]) {
    int rank, num_procs;
    long int n;
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
    
    if (rank == 0) {
        master(n, num_procs);
    } else {
        worker();
    }
    
    MPI_Barrier(MPI_COMM_WORLD);
    fim = MPI_Wtime();
    
    if (rank == 0) {
        printf("Tempo: %.4f segundos\n", fim - inicio);
    }
    
    MPI_Finalize();
    return 0;
}