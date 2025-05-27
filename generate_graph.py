import matplotlib.pyplot as plt
import pandas as pd


def calcular_speedup(df, n_value):
    df_n = df[df["N"] == n_value]

    sequencial_row = df_n[df_n["Versao"] == "Sequencial"]

    if sequencial_row.empty:
        raise ValueError(f"Nenhuma entrada 'Sequencial' encontrada para N = {n_value}")

    tempo_seq = sequencial_row["Tempo"].iloc[0]

    speedup_data = {"Procs": [], "Versao1": [], "Versao2": []}

    for procs in range(2, 17):
        speedup_data["Procs"].append(procs)

        tempo_v1 = df_n[(df_n["Versao"] == "Versao1") & (df_n["Procs"] == procs)]["Tempo"]
        if not tempo_v1.empty:
            speedup_v1 = tempo_seq / tempo_v1.iloc[0]
            speedup_data["Versao1"].append(speedup_v1)
        else:
            speedup_data["Versao1"].append(0)

        tempo_v2 = df_n[(df_n["Versao"] == "Versao2") & (df_n["Procs"] == procs)]["Tempo"]
        if not tempo_v2.empty:
            speedup_v2 = tempo_seq / tempo_v2.iloc[0]
            speedup_data["Versao2"].append(speedup_v2)
        else:
            speedup_data["Versao2"].append(0)

    return speedup_data


def gerar_graficos():
    df = pd.read_csv(
        "resultados_finais.txt", comment="#", names=["N", "Procs", "Versao", "Tempo", "Primos", "JobID"]
    )


    df = df.apply(lambda x: x.str.strip() if x.dtype == "object" else x)
    df["Versao"] = df["Versao"].str.strip() 

    df["N"] = df["N"].astype(int)
    df["Procs"] = df["Procs"].astype(int)
    df["Tempo"] = df["Tempo"].astype(float)

    plt.figure(figsize=(12, 8))

    plt.subplot(2, 1, 1)
    speedup_100m = calcular_speedup(df, 100000000)
    plt.plot(
        speedup_100m["Procs"],
        speedup_100m["Versao1"],
        "b-o",
        label="Versão 1 - Distribuição por Saltos",
    )
    plt.plot(
        speedup_100m["Procs"],
        speedup_100m["Versao2"],
        "r-s",
        label="Versão 2 - Saco de Tarefas",
    )
    plt.plot(range(2, 17), range(2, 17), "k--", alpha=0.5, label="Speedup Ideal")
    plt.xlabel("Número de Processadores")
    plt.ylabel("Speedup")
    plt.title("Speedup para N = 100.000.000")
    plt.legend()
    plt.grid(True, alpha=0.3)

    plt.subplot(2, 1, 2)
    speedup_1b = calcular_speedup(df, 1000000000)
    plt.plot(
        speedup_1b["Procs"],
        speedup_1b["Versao1"],
        "b-o",
        label="Versão 1 - Distribuição por Saltos",
    )
    plt.plot(
        speedup_1b["Procs"],
        speedup_1b["Versao2"],
        "r-s",
        label="Versão 2 - Saco de Tarefas",
    )
    plt.plot(range(2, 17), range(2, 17), "k--", alpha=0.5, label="Speedup Ideal")
    plt.xlabel("Número de Processadores")
    plt.ylabel("Speedup")
    plt.title("Speedup para N = 1.000.000.000")
    plt.legend()
    plt.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig("speedup_comparison.png", dpi=300, bbox_inches="tight")
    plt.show()


if __name__ == "__main__":
    gerar_graficos()
