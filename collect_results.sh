#!/bin/bash

HOME_DIR="/home/aluno/mpi-primes"
RESULTS_DIR="$HOME_DIR/resultados"
FINAL_RESULTS="$RESULTS_DIR/resultados_finais.txt"

echo "Coletando resultados dos jobs..."

if [ ! -d "$RESULTS_DIR" ]; then
    echo "Erro: Diretório de resultados não encontrado: $RESULTS_DIR"
    exit 1
fi

echo "# Resultados dos testes de primos" > $FINAL_RESULTS
echo "# Formato: N, Procs, Versao, Tempo, Primos, JobID" >> $FINAL_RESULTS

JOBS_FILE="$RESULTS_DIR/jobs_submetidos.txt"

if [ ! -f "$JOBS_FILE" ]; then
    echo "Erro: Arquivo de jobs não encontrado: $JOBS_FILE"
    echo "Execute primeiro o script submit_all_tests.sh"
    exit 1
fi

TOTAL_JOBS=0
PROCESSED_JOBS=0
ERROR_JOBS=0

echo "Processando resultados..."

while IFS=', ' read -r job_id n procs versao; do
    if [[ $job_id == \#* ]]; then
        continue
    fi
    
    TOTAL_JOBS=$((TOTAL_JOBS + 1))
    
    OUTPUT_FILES=$(find . -name "*.qsub.o$job_id" -o -name "*.$job_id" 2>/dev/null)
    
    JOB_PROCESSED=0
    
    for output_file in $OUTPUT_FILES; do
        if [ -f "$output_file" ]; then
            echo "Processando $output_file para job $job_id..."
            
            # Verificar se há erros no job
            if grep -q -i "error\|erro\|failed\|falha" "$output_file"; then
                echo "  ⚠ Job $job_id contém erros"
                ERROR_JOBS=$((ERROR_JOBS + 1))
                continue
            fi
            
            TEMPO=""
            PRIMOS=""
            
            if [[ $versao == "Sequencial" ]]; then
                TEMPO=$(grep "Tempo:" "$output_file" | awk '{print $2}' | sed 's/segundos//')
                PRIMOS=$(grep "Quant. de primos" "$output_file" | awk '{print $6}')
            else
                TEMPO=$(grep -E "(Tempo:|Tempo de execucao:)" "$output_file" | tail -1 | awk '{print $NF}' | sed 's/segundos//')
                PRIMOS=$(grep -E "(Quant. de primos|Quantidade de primos)" "$output_file" | awk '{print $NF}')
            fi
            
            if [ ! -z "$TEMPO" ] && [ ! -z "$PRIMOS" ]; then
                echo "$n, $procs, $versao, $TEMPO, $PRIMOS, $job_id" >> $FINAL_RESULTS
                echo "  ✓ Job $job_id: N=$n, Procs=$procs, Versao=$versao, Tempo=$TEMPO, Primos=$PRIMOS"
                PROCESSED_JOBS=$((PROCESSED_JOBS + 1))
                JOB_PROCESSED=1
            else
                echo "  ⚠ Não foi possível extrair dados válidos do job $job_id"
                echo "  Conteúdo do arquivo:"
                cat "$output_file" | head -20
                echo "  ..."
                ERROR_JOBS=$((ERROR_JOBS + 1))
            fi
            break
        fi
    done
    
    if [ $JOB_PROCESSED -eq 0 ] && [ -z "$OUTPUT_FILES" ]; then
        echo "  ⚠ Arquivo de saída não encontrado para job $job_id"
        ERROR_JOBS=$((ERROR_JOBS + 1))
    fi
    
done < <(tail -n +3 "$JOBS_FILE")

echo ""
echo "==============================================="
echo "Coleta de resultados concluída!"
echo "==============================================="
echo "Total de jobs: $TOTAL_JOBS"
echo "Jobs processados com sucesso: $PROCESSED_JOBS"
echo "Jobs com erro ou sem dados: $ERROR_JOBS"
echo "Resultados salvos em: $FINAL_RESULTS"

if [ $PROCESSED_JOBS -gt 0 ]; then
    echo ""
    echo "Estatísticas dos resultados:"
    echo "============================"
    echo "Jobs por versão:"
    grep -v "^#" "$FINAL_RESULTS" | cut -d',' -f3 | sort | uniq -c
    
    echo ""
    echo "Jobs por valor de N:"
    grep -v "^#" "$FINAL_RESULTS" | cut -d',' -f1 | sort | uniq -c
    
    echo ""
    echo "Preview dos resultados:"
    head -10 "$FINAL_RESULTS"
fi

if [ $ERROR_JOBS -gt 0 ]; then
    echo ""
    echo "⚠ Alguns jobs apresentaram problemas. Verifique os arquivos de saída manualmente."
fi

SUMMARY_FILE="$RESULTS_DIR/sumario.txt"
echo "Sumário da Execução - $(date)" > $SUMMARY_FILE
echo "=====================================" >> $SUMMARY_FILE
echo "Total de jobs submetidos: $TOTAL_JOBS" >> $SUMMARY_FILE
echo "Jobs processados com sucesso: $PROCESSED_JOBS" >> $SUMMARY_FILE
echo "Jobs com erro: $ERROR_JOBS" >> $SUMMARY_FILE
echo "" >> $SUMMARY_FILE
echo "Arquivos gerados:" >> $SUMMARY_FILE
echo "- Resultados: $FINAL_RESULTS" >> $SUMMARY_FILE
echo "- Jobs submetidos: $JOBS_FILE" >> $SUMMARY_FILE
echo "- Este sumário: $SUMMARY_FILE" >> $SUMMARY_FILE

echo ""
echo "Sumário salvo em: $SUMMARY_FILE"