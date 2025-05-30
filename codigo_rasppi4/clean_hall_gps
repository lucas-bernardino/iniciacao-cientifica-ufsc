import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

df = pd.read_csv("TESTE_PIGA_QUINTAFEIRA.csv")

MAX = 120

# Vout = 0.05 x Pin+0.376
# Pin = (Vout - 0.376) / 0.05

brake_voltage = df["Pressao Freio"].to_numpy()
df["Pressao Freio"] = (brake_voltage - 0.376) / 0.05

n = [i for i in range(len(df["Pressao Freio"]))]

velocidade_raw = df["Velocidade: "].to_numpy() 

velocidade_masked = np.where(
    velocidade_raw > MAX,
    np.nan,
    velocidade_raw
)

velocidade_interp = pd.Series(velocidade_masked).interpolate().fillna(method='bfill').fillna(method='ffill').to_numpy()

filtered_values = []
for value in df["Velocidade: "]:
    if value < MAX:
        filtered_values.append(value)

print(df["Velocidade: "])

new_n = range(len(filtered_values))


df.to_csv("TESTE_FREIO_BAR.csv", index=False) 
plt.plot(n, df["Pressao Freio"], label="Pressao Freio")
plt.plot(n, df["Velocidade GPS"], label="Velocidade GPS")
plt.plot(n, velocidade_interp, label="Velocidade Hall C/ Filtro")
plt.xlabel("[N]")
plt.ylabel("BAR")
plt.legend()
plt.title("Pressão [BAR] ao longo do tempo")

plt.show()
