#!/bin/bash

N_VALUES=(100000000 1000000000)
PROCS=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16)
HOME_DIR="/home/aluno/braga"
RESULTS_DIR="$HOME_DIR/resultados"

mkdir -p $RESULTS_DIR

echo "Compilando programas..."
gcc -o $HOME_DIR/sequencial $HOME_DIR/sequencial.c -lm
mpicc -o $HOME_DIR/paralelo_v1 $HOME_DIR/paralelo_v1.c -lm
mpicc -o $HOME_DIR/paralelo_v2 $HOME_DIR/paralelo_v2.c -lm

echo "Verificando se a compilação foi bem-sucedida..."
if [ ! -f "$HOME_DIR/sequencial" ]; then
    echo "Erro: Falha na compilação do programa sequencial"
    exit 1
fi

if [ ! -f "$HOME_DIR/paralelo_v1" ]; then
    echo "Erro: Falha na compilação do paralelo_v1"
    exit 1
fi

if [ ! -f "$HOME_DIR/paralelo_v2" ]; then
    echo "Erro: Falha na compilação do paralelo_v2"
    exit 1
fi

JOBS_FILE="$RESULTS_DIR/jobs_submetidos.txt"
echo "# Jobs submetidos" > $JOBS_FILE
echo "# Formato: JobID, N, Procs, Versao" >> $JOBS_FILE

echo "Submetendo jobs para o cluster..."

for N in "${N_VALUES[@]}"; do
    echo "Submetendo jobs para N = $N"
    
    echo "Submetendo job sequencial..."
    JOB_ID=$(qsub -pe smp 1 -v N_VALUE=$N $HOME_DIR/sequencial.qsub | awk '{print $3}')
    echo "$JOB_ID, $N, 1, Sequencial" >> $JOBS_FILE
    echo "Job sequencial submetido: $JOB_ID"
    
    for P in "${PROCS[@]}"; do
        if [ $P -eq 1 ]; then
            continue
        fi
        
        echo "Submetendo jobs para $P processadores..."
        
        JOB_ID_V1=$(qsub -pe mpi $P -v N_VALUE=$N $HOME_DIR/paralelo_v1.qsub | awk '{print $3}')
        echo "$JOB_ID_V1, $N, $P, Versao1" >> $JOBS_FILE
        echo "Job V1 submetido: $JOB_ID_V1 (P=$P)"
        
        JOB_ID_V2=$(qsub -pe mpi $P -v N_VALUE=$N $HOME_DIR/paralelo_v2.qsub | awk '{print $3}')
        echo "$JOB_ID_V2, $N, $P, Versao2" >> $JOBS_FILE
        echo "Job V2 submetido: $JOB_ID_V2 (P=$P)"
        
        sleep 2
    done
done

echo ""
echo "=============================================="
echo "Todos os jobs foram submetidos!"
echo "Total de jobs: $((${#N_VALUES[@]} * ${#PROCS[@]} * 2))"
echo "=============================================="
echo ""
echo "Para verificar o status dos jobs use:"
echo "  qstat"
echo "  ou: ./check_jobs.sh"
echo ""
echo "Para coletar os resultados após conclusão use:"
echo "  ./collect_results.sh"