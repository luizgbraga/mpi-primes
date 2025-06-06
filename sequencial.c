
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

int primo(long int n)
{
    long int i;

    for (i = 3; i < (int)(sqrt(n) + 1); i += 2)
        if ((n % i) == 0)
            return 0;

    return 1;
}

int main(int argc, char *argv[])
{

    int total = 0;
    long int i, n;
    clock_t inicio, fim;

    if (argc < 2)
    {
        printf("Valor invalido! Entre com o valor do maior inteiro\n");
        return 0;
    }
    else
    {
        n = strtol(argv[1], (char **)NULL, 10);
    }

    inicio = clock();
    for (i = 3; i <= n; i += 2)
        if (primo(i) == 1)
            total++;

    total += 1; /* Contabiliza o 2 que é primo */
    fim = clock();
    printf("Quant. de primos entre 1 e n: %d\nTempo: %.2lf mseg\n", total, ((double)(fim - inicio)) / CLOCKS_PER_SEC);
    return 0;
}