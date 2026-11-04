# ODIS-E — Blocos de valores medidos (com descrições)

Guia prático para acessar, montar e ler **blocos de valores medidos** (measured value blocks / MWB) no ODIS Engineering, com **descrições, unidades e endereço da ECU**.

> Testado no ODIS-E 21.0.1 em português (pt_PT) com VW Gol G5 2012 (VIN `9BWAA05U4CP005118`), interface Autel MaxiVCI V200 (MX2) via J2534.

---

## 1. Pré-requisitos

| Item | Observação |
|---|---|
| Projeto correto | Para o Gol G5 2012: **`VW25X`** (motor LT3 / **KWP2000 CAN20**). `VWVIN` serve só para ler o VIN; `VW27XLA` é UDS (Gol mais novo) |
| VCI | `Autel MaxiVCI V200 (MX2)` selecionada |
| Veículo | Ignição **ligada** (status `KL15`; `KL30` = só bateria) |
| Módulo | ECU do motor (`0001`) respondendo (sem X vermelho) |

---

## 2. Entrar no diagnóstico

1. Abra o ODIS (`OffboardDiagLauncher.exe`)
2. Selecione o **projeto do veículo** (`VW25X`) no seletor
3. Confirme a interface: **`Lig.: Autel MaxiVCI V200 (MX2)`**
4. Clique em **`Acesso ao diagnóstico`**
5. Identifique o veículo:
   - automático pelo **VIN** (`ID do veículo`), ou
   - **seleção manual** (marca → modelo → ano → motor)
6. Abra o módulo desejado, ex.: **`0001 — Sistema eletrônico do motor`**
   - a conexão deve ficar **verde/OK** (sem “X”)

---

## 3. Abrir a seleção de valores medidos

No módulo aberto:

1. Menu **`Valores de medição`** → **`Selecionar valores de medição`**
2. A tela tem duas listas:

| Lista | Significado |
|---|---|
| **Esquerda — `Nome` / `RDID`** | Valores **disponíveis na ECU** (descrições vindas do projeto) |
| **Direita — `Seleção` / `End.`** | Valores **escolhidos** para leitura; `End.` = endereço da ECU (ex.: `0001`) |

3. Se a lista da esquerda estiver **vazia**: ECU não conectada ou projeto errado (veja seção 7)

---

## 4. Montar o bloco de valores

1. Na lista da esquerda, **selecione um ou mais valores** (Ctrl/Shift para múltiplos)
2. Use as setas para mover:
   - **`>>`** adiciona todos / **`>`** adiciona o selecionado
   - **`<`** remove o selecionado / **`<<`** limpa a seleção
   - **↑ / ↓** reordenam os valores no bloco
3. Opcional: **`Pré-definição…`** carrega um **bloco pré-definido** do projeto (conjuntos padrão de valores)
4. Em **`Bloco val. med. Posição`** escolha a posição do bloco (a barra colorida indica a cor/posição)
5. Em **`Marcador do valor de medição`** defina um marcador de referência (opcional)
6. Clique em **`Aceitar`** para abrir a leitura em tempo real

> Dica: para ver **descrições/unidades** na tabela, use o botão direito no cabeçalho das colunas e habilite colunas como **Descrição**, **Unidade**, **Valor atual**, **Mín.**, **Máx.**

---

## 5. Leitura em tempo real

Após `Aceitar`, a tela de medição mostra:

- **Tabela**: nome/descrição, valor atual, unidade, mín/máx
- **Gráfico**: selecione os valores e alterne para o modo gráfico
- **Atualização**: os valores são atualizados continuamente enquanto a ECU responde
- **Incluir/remover valores** durante a leitura: volte em `Selecionar valores de medição` e ajuste a lista
- **Gravar/exportar**: use as opções de gravação/exportação da tela de medição

### Blocos pré-definidos

`Pré-definição…` traz conjuntos prontos (ex.: valores de motor, temperatura, pressão). É o caminho mais rápido para começar; depois você pode adicionar/remover itens.

---

## 6. Exemplo no Gol G5

1. Projeto **`VW25X`**
2. `Acesso ao diagnóstico` → VIN `9BWAA05U4CP005118`
3. `0001 — Sistema eletrônico do motor`
4. `Valores de medição` → `Selecionar valores de medição`
5. Selecione, por exemplo: rotação, temperatura do líquido de arrefecimento, tensão da bateria, lambda, avanço
6. `Aceitar` → leitura em tempo real
7. Salve o bloco para reutilizar

---

## 7. Problemas comuns

| Sintoma | Causa provável | Solução |
|---|---|---|
| Lista da esquerda **vazia** | Projeto `VWVIN` (só VIN) ou ECU sem conexão | Use `VW25X`, ligue a ignição e confirme o módulo `0001` verde |
| Valores sem **descrição** | Projeto/variante sem dados MCD da ECU | Confirme o projeto/ano/motor corretos |
| `KL30` em vez de `KL15` | Ignição desligada ou sem reconhecimento | Ligue a ignição; reabra o diagnóstico |
| Módulos com **X vermelho** | Sem comunicação (protocolo/cabeamento/projeto) | Ver `docs/odis.md` (seção de problemas) e o log da PDU |
| Lista preenche mas valores não atualizam | ECU não responde às requisições | Verifique protocolo (KWP2000 CAN20) e logs da PDU |

### Logs úteis

- `C:\ProgramData\OE\log\engine.log` — sessão do ODIS
- `C:\ProgramData\Volkswagen\VW_D_PDU_API_OE\logs\PDUAPI_VW*.log` — comunicação VCI/ECU
- `C:\ProgramData\OE\sessions` — sessões salvas
