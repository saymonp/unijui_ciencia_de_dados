# TRABALHO 3 - ETAPA 2: ANÁLISE EXPLORATÓRIA E PROCESSAMENTO DE DADOS (PANDAS)
Análise dos dados ambulatoriais do SIA/SUS referentes ao município de Ijuí/RS.

## 1. Importação das Bibliotecas


```python
import pandas as pd
import numpy as np
from sqlalchemy import create_engine
```

## 2. Conexão com o Banco de Dados e Carga da VIEW


```python
USER = "root"
PASSWORD = "rootpassword"
HOST = "127.0.0.1"
PORT = "3306"
DATABASE = "dbsia"

engine = create_engine(
    f"mysql+pymysql://{USER}:{PASSWORD}@{HOST}:{PORT}/{DATABASE}?charset=utf8mb4"
)

print("Conectando ao banco de dados e carregando a VIEW pa_ijui...")
query = "SELECT * FROM pa_ijui;"
df_ijui = pd.read_sql(query, engine)
print(f"Carga concluída! Total de registros carregados: {len(df_ijui):,}")
```

    Conectando ao banco de dados e carregando a VIEW pa_ijui...
    Carga concluída! Total de registros carregados: 60,282
    

## 3. Exploração Inicial e Verificação de Nulos


```python
print("--- Dimensões do DataFrame ---")
print(f"Linhas: {df_ijui.shape[0]:,} | Colunas: {df_ijui.shape[1]}")

print("\n--- Verificação de Valores Nulos / Ausentes (Bruto) ---")
print(df_ijui.isnull().sum())
```

    --- Dimensões do DataFrame ---
    Linhas: 60,282 | Colunas: 17
    
    --- Verificação de Valores Nulos / Ausentes (Bruto) ---
    Ano                             0
    Mes                             0
    AnoBimestre                     0
    AnoTrimestre                    0
    Estabelecimento              7271
    Procedimento                    0
    Ocupacao                        0
    pa_sexo                         0
    pa_idade                        0
    pa_cidpri                       0
    Diagnostico                 49350
    MunicipioEstabelecimento        0
    MunicipioPaciente               0
    pa_qtdpro                       0
    pa_qtdapr                       0
    pa_valpro                       0
    pa_valapr                       0
    dtype: int64
    

## 4. Limpeza, Tipagem e Padronização dos Dados


```python
# Conversão de colunas DECIMAL para tipos numéricos
cols_numericas = ['pa_qtdpro', 'pa_qtdapr', 'pa_valpro', 'pa_valapr']
for col in cols_numericas:
    df_ijui[col] = pd.to_numeric(df_ijui[col], errors='coerce').fillna(0)

# Tratamento da idade (999 = ignorada no DATASUS)
df_ijui['Idade_Num'] = pd.to_numeric(df_ijui['pa_idade'], errors='coerce')
df_ijui.loc[df_ijui['Idade_Num'] >= 999, 'Idade_Num'] = np.nan

# Padronização de rótulos
df_ijui['Diagnostico'] = (
    df_ijui['Diagnostico']
    .fillna('')
    .str.strip()
    .replace({'': 'Não informado / Não exigido', '*': 'Não informado / Não exigido'})
)

df_ijui['Estabelecimento'] = df_ijui['Estabelecimento'].fillna('Estabelecimento não identificado')
df_ijui['Procedimento'] = df_ijui['Procedimento'].fillna('Procedimento não identificado')
df_ijui['Ocupacao'] = df_ijui['Ocupacao'].fillna('Ocupação não informada')
df_ijui['MunicipioPaciente'] = df_ijui['MunicipioPaciente'].fillna('Município não identificado')

# Mapeamento do sexo
mapa_sexo = {'M': 'Masculino', 'F': 'Feminino', '0': 'Não informado', 'I': 'Não informado'}
df_ijui['Sexo_Desc'] = df_ijui['pa_sexo'].map(mapa_sexo).fillna('Não informado')

print("--- Estrutura Após Tratamento ---")
print(df_ijui.info())
```

    --- Estrutura Após Tratamento ---
    <class 'pandas.DataFrame'>
    RangeIndex: 60282 entries, 0 to 60281
    Data columns (total 19 columns):
     #   Column                    Non-Null Count  Dtype  
    ---  ------                    --------------  -----  
     0   Ano                       60282 non-null  int64  
     1   Mes                       60282 non-null  int64  
     2   AnoBimestre               60282 non-null  str    
     3   AnoTrimestre              60282 non-null  str    
     4   Estabelecimento           60282 non-null  str    
     5   Procedimento              60282 non-null  str    
     6   Ocupacao                  60282 non-null  str    
     7   pa_sexo                   60282 non-null  str    
     8   pa_idade                  60282 non-null  str    
     9   pa_cidpri                 60282 non-null  str    
     10  Diagnostico               60282 non-null  str    
     11  MunicipioEstabelecimento  60282 non-null  str    
     12  MunicipioPaciente         60282 non-null  str    
     13  pa_qtdpro                 60282 non-null  float64
     14  pa_qtdapr                 60282 non-null  float64
     15  pa_valpro                 60282 non-null  float64
     16  pa_valapr                 60282 non-null  float64
     17  Idade_Num                 59210 non-null  float64
     18  Sexo_Desc                 60282 non-null  str    
    dtypes: float64(5), int64(2), str(12)
    memory usage: 8.7 MB
    None
    

## 5. Análises Estratégicas de Gestão Municipal (Ijuí/RS)
### 5.1 Volume e Evolução Temporal


```python
vol_tempo = df_ijui.groupby(['Ano', 'AnoTrimestre', 'Mes'], dropna=False).agg(
    Registros=('pa_qtdapr', 'count'),
    Qtd_Apresentada=('pa_qtdpro', 'sum'),
    Qtd_Aprovada=('pa_qtdapr', 'sum'),
    Valor_Aprovado=('pa_valapr', 'sum')
).reset_index()

print(vol_tempo.to_string(index=False))
```

     Ano AnoTrimestre  Mes  Registros  Qtd_Apresentada  Qtd_Aprovada  Valor_Aprovado
    2026       2026T2    6      60282         452592.0      364022.0      5436537.16
    

### 5.2 Ranking dos Estabelecimentos de Saúde (Top 15 por Valor)


```python
ranking_est = df_ijui.groupby('Estabelecimento').agg(
    Atendimentos=('pa_qtdapr', 'sum'),
    Valor_Total=('pa_valapr', 'sum')
).sort_values(by='Valor_Total', ascending=False)

print(ranking_est.head(15))
```

                                                        Atendimentos  Valor_Total
    Estabelecimento                                                              
    HOSPITAL DE CLINICAS IJUI                                38173.0   3188059.32
    17 COORDENADORIA REGIONAL DE SAUDE                      189163.0    793719.38
    CENTRO AUDITIVO PROAUDI                                   2677.0    254915.09
    HOSPITAL BOM PASTOR IJUI                                  2543.0    250495.86
    POSTO CENTRAL SECRETARIA MUNICIPAL DE SAUDE DE ...       26077.0    231071.84
    CER III UNIR                                              3773.0    217614.65
    CISA                                                     26364.0    181245.31
    LABORATORIO DE ANALISES CLINICAS UNILAB                  27552.0    135172.34
    Estabelecimento não identificado                         17372.0     94206.42
    UNIDADE DE PRONTO ATENDIMENTO DR MARTIN CESAR A...       19917.0     58857.24
    CENTRO DE ATENCAO PSICOSSOCIAL CAPS COLMEIA               2987.0      8180.79
    LABORATORIO OSVALDO CRUZ                                  1224.0      7688.94
    LABORATORIO MALLMANN                                      1346.0      6958.61
    CENTRO DE ATENCAO PSICOSSOCIAL CAPS INFANTIL CA...        3077.0      3323.70
    CENTRO DE ESPECIALIDADES ODONTOLOGICAS REGIONAL...         539.0      3008.73
    

### 5.3 Perfil Demográfico dos Pacientes (Sexo e Idade)


```python
print("--- Distribuição por Sexo ---")
dist_sexo = df_ijui.groupby('Sexo_Desc').agg(
    Registros=('pa_qtdapr', 'count'),
    Qtd_Aprovada=('pa_qtdapr', 'sum')
)
dist_sexo['Percentual (%)'] = (dist_sexo['Qtd_Aprovada'] / dist_sexo['Qtd_Aprovada'].sum() * 100).round(2)
print(dist_sexo)

print("\n--- Estatísticas de Idade (Anos) ---")
print(df_ijui['Idade_Num'].describe().round(1))
```

    --- Distribuição por Sexo ---
                   Registros  Qtd_Aprovada  Percentual (%)
    Sexo_Desc                                             
    Feminino           27768      128676.0           35.35
    Masculino          28211      101983.0           28.02
    Não informado       4303      133363.0           36.64
    
    --- Estatísticas de Idade (Anos) ---
    count    59210.0
    mean        50.8
    std         23.2
    min          0.0
    25%         35.0
    50%         56.0
    75%         69.0
    max        106.0
    Name: Idade_Num, dtype: float64
    

### 5.4 Top 10 Diagnósticos (CID) Mais Frequentes


```python
top_cid = (
    df_ijui[df_ijui['Diagnostico'] != 'Não informado / Não exigido']
    .groupby('Diagnostico')['pa_qtdapr']
    .sum()
    .sort_values(ascending=False)
    .head(10)
)

print(top_cid)
```

    Diagnostico
    CID NÃO IDENTIFICADO                                  9003.0
    K51.0 Enterocolite ulcerativa                         5996.0
    J44.0 Doen pulm obs cron c/inf resp ag tr resp inf    4943.0
    M05.8 Outr artrites reumatoides soro-positivas        4640.0
    R52.1 Dor cronica intratavel                          4047.0
    G40.0 Epilep sind epil idiop def loc cris inic foc    3771.0
    I50.0 Insuf cardiaca congestiva                       2877.0
    F31.6 Transt afetivo bipolar episodio atual misto     2400.0
    J44.8 Outr form espec doenc pulmonar obstrut cron     2274.0
    K74.3 Cirrose biliar prim                             1950.0
    Name: pa_qtdapr, dtype: float64
    

### 5.5 Fluxo Regional: Origem dos Pacientes Atendidos em Ijuí (Top 10)


```python
fluxo_pacientes = df_ijui.groupby('MunicipioPaciente').agg(
    Total_Atendimentos=('pa_qtdapr', 'sum'),
    Valor_Investido=('pa_valapr', 'sum')
).sort_values(by='Total_Atendimentos', ascending=False)

print(fluxo_pacientes.head(10))
```

                       Total_Atendimentos  Valor_Investido
    MunicipioPaciente                                     
    Invalido                     133363.0        718058.80
    Ijui                          94921.0       1382599.56
    Panambi                       33634.0        380569.54
    Crissiumal                    13193.0        124194.44
    Catuipe                        8373.0        158087.56
    Santo Augusto                  8220.0        128729.45
    Condor                         8118.0         69331.58
    Augusto Pestana                7764.0        115636.25
    Joia                           7327.0        126485.20
    Ajuricaba                      6993.0         68953.72
    

### 5.6 Análise Financeira: Produzido vs Aprovado


```python
total_apresentado = df_ijui['pa_valpro'].sum()
total_aprovado = df_ijui['pa_valapr'].sum()
diferenca = total_apresentado - total_aprovado
perc_aprovacao = (total_aprovado / total_apresentado * 100) if total_apresentado > 0 else 0

print(f"Total Apresentado:   R$ {total_apresentado:,.2f}")
print(f"Total Aprovado:      R$ {total_aprovado:,.2f}")
print(f"Diferença / Glosa:   R$ {diferenca:,.2f}")
print(f"Taxa de Aprovação:   {perc_aprovacao:.2f}%")
```

    Total Apresentado:   R$ 5,557,640.99
    Total Aprovado:      R$ 5,436,537.16
    Diferença / Glosa:   R$ 121,103.83
    Taxa de Aprovação:   97.82%
    


```python

```
