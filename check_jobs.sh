#!/bin/bash

HOME_DIR="/home/aluno/mpi-primes"
RESULTS_DIR="$HOME_DIR/resultados"
JOBS_FILE="$RESULTS_DIR/jobs_submetidos.txt"

echo "Verificando status dos jobs..."

if [ ! -f "$JOBS_FILE" ]; then
    echo "Erro: Arquivo de jobs não encontrado: $JOBS_FILE"
    echo "Execute primeiro o script submit_all_tests.sh"
    exit 1
fi

TOTAL_JOBS=0
COMPLETED_JOBS=0
RUNNING_JOBS=0
PENDING_JOBS=0
ERROR_JOBS=0

echo "Status detalhado dos jobs:"
echo "=========================="

while IFS=', ' read -r job_id n procs versao; do
    if [[ $job_id == \#* ]]; then
        continue
    fi
    
    TOTAL_JOBS=$((TOTAL_JOBS + 1))
    
    if qstat | grep -q "$job_id" 2>/dev/null; then
        STATUS=$(qstat | grep "$job_id" | awk '{print $5}')
        if [[ $STATUS == "r" ]]; then
            RUNNING_JOBS=$((RUNNING_JOBS + 1))
            echo "Job $job_id: EXECUTANDO ($versao, N=$n, P=$procs)"
        elif [[ $STATUS == "qw" ]]; then
            PENDING_JOBS=$((PENDING_JOBS + 1))
            echo "Job $job_id: PENDENTE ($versao, N=$n, P=$procs)"
        else
            echo "Job $job_id: STATUS=$STATUS ($versao, N=$n, P=$procs)"
        fi
    else
        OUTPUT_FILES=$(find . -name "*.qsub.o$job_id" -o -name "*.$job_id" 2>/dev/null)
        if [ ! -z "$OUTPUT_FILES" ]; then
            ERROR_COUNT=0
            for output_file in $OUTPUT_FILES; do
                if grep -q -i "error\|erro\|failed\|falha" "$output_file"; then
                    ERROR_COUNT=$((ERROR_COUNT + 1))
                fi
            done
            
            if [ $ERROR_COUNT -gt 0 ]; then
                ERROR_JOBS=$((ERROR_JOBS + 1))
                echo "Job $job_id: ERRO ($versao, N=$n, P=$procs)"
            else
                COMPLETED_JOBS=$((COMPLETED_JOBS + 1))
                echo "Job $job_id: CONCLUÍDO ($versao, N=$n, P=$procs)"
            fi
        else
            echo "Job $job_id: STATUS DESCONHECIDO ($versao, N=$n, P=$procs)"
        fi
    fi
    
done < <(tail -n +3 "$JOBS_FILE")

echo ""
echo "Resumo dos Jobs:"
echo "================"
echo "Total de jobs: $TOTAL_JOBS"
echo "Concluídos com sucesso: $COMPLETED_JOBS"
echo "Com erro: $ERROR_JOBS"
echo "Executando: $RUNNING_JOBS"
echo "Pendentes: $PENDING_JOBS"

FINISHED_JOBS=$((COMPLETED_JOBS + ERROR_JOBS))
echo "Finalizados (sucesso + erro): $FINISHED_JOBS"

if [ $FINISHED_JOBS -eq $TOTAL_JOBS ]; then
    echo ""
    echo "✓ Todos os jobs concluídos!"
    if [ $ERROR_JOBS -eq 0 ]; then
        echo "✓ Todos os jobs concluídos com sucesso!"
        echo "Execute collect_results.sh para coletar os resultados."
    else
        echo "⚠ Alguns jobs terminaram com erro. Verifique os arquivos de saída."
    fi
elif [ $RUNNING_JOBS -gt 0 ] || [ $PENDING_JOBS -gt 0 ]; then
    echo ""
    echo "Jobs ainda em execução ou pendentes."
    echo "Execute este script novamente mais tarde."
fi

echo ""
echo "Jobs ativos no sistema (qstat):"
echo "================================"
qstat