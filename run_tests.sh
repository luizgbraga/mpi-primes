N_VALUES=(100000000 1000000000)

PROCS=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16)

echo "Compilando programas..."
gcc -o sequencial sequencial.c -lm
mpicc -o paralelo_v1 paralelo_v1.c -lm
mpicc -o paralelo_v2 paralelo_v2.c -lm

RESULTS_FILE="resultados.txt"
echo "# Resultados dos testes" > $RESULTS_FILE
echo "# Formato: N, Procs, Versao, Tempo, Primos" >> $RESULTS_FILE

for N in "${N_VALUES[@]}"; do
    echo "Testando N = $N"
    
    echo "Executando versão sequencial..."
    SEQ_OUTPUT=$(./sequencial $N)
    SEQ_TIME=$(echo "$SEQ_OUTPUT" | grep "Tempo:" | awk '{print $2}')
    SEQ_PRIMOS=$(echo "$SEQ_OUTPUT" | grep "Quant. de primos" | awk '{print $6}')
    echo "$N, 1, Sequencial, $SEQ_TIME, $SEQ_PRIMOS" >> $RESULTS_FILE
    
    for P in "${PROCS[@]}"; do
        if [ $P -eq 1 ]; then
            continue
        fi
        
        echo "Testando com $P processadores..."
        
        # Versão 1
        V1_OUTPUT=$(mpirun -n $P ./paralelo_v1 $N)
        V1_TIME=$(echo "$V1_OUTPUT" | grep "Tempo:" | awk '{print $2}')
        V1_PRIMOS=$(echo "$V1_OUTPUT" | grep "Quant. de primos" | awk '{print $6}')
        echo "$N, $P, Versao1, $V1_TIME, $V1_PRIMOS" >> $RESULTS_FILE
        
        # Versão 2
        V2_OUTPUT=$(mpirun -n $P ./paralelo_v2 $N)
        V2_TIME=$(echo "$V2_OUTPUT" | grep "Tempo:" | awk '{print $2}')
        V2_PRIMOS=$(echo "$V2_OUTPUT" | grep "Quant. de primos" | awk '{print $6}')
        echo "$N, $P, Versao2, $V2_TIME, $V2_PRIMOS" >> $RESULTS_FILE
    done
done

echo "Testes concluídos. Resultados salvos em $RESULTS_FILE"