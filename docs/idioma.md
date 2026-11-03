# Trocar o idioma do DiagBox

O idioma da interface é definido em **um único arquivo**:

```
C:\AWRoot\dtrd\trans\Language.ini
```

```ini
[LANGUAGE]
Current=pt_BR
```

> O valor é o **código de locale** (`pt_BR`, `pt_PT`, `en_GB`, `fr_FR`, `zh_CN`, …). Trocá-lo é suficiente — launcher, aplicação de diagnóstico e dicionários passam a usar a tradução correspondente após reiniciar.

## Quem lê esse arquivo

| Arquivo | Referência |
|---|---|
| `C:\AWRoot\bin\launcher\ap.ini` | `PATH_LG_DICO=/AWRoot/dtrd/trans/Language.ini` |
| `C:\AWRoot\bin\fi\AWFInterpreter_vc80.ini` | `LanguageIniFile=\AWRoot\dtrd\trans\` e `[LANGUAGE_DATA] DATA_FILE=...\Language.ini` |
| `C:\AWRoot\bin\common\AWMMIStub.ini` | `LanguageIniFile=\AWRoot\dtrd\trans\Language.ini` |

Os dicionários ficam em `C:\AWRoot\dtrd\trans\` no formato `<MÓDULO><locale>.DU8` (`LAUNCHER`, `AWMMI`, `DBMMI`, `ENGINE`, `POLUXDATA`, `POLUXMES`, `POLUXPORT`, `POLUXSPV`, `POLUXVEH`, `POLUXXPERT`, `VEHMNT`). **Os `.DU8` são traduções, não firmware** — trocar o idioma não altera nada relacionado à VCI/veículo.

## Idiomas disponíveis (com dicionário completo `LAUNCHER*.DU8`)

| Código | Idioma | Código | Idioma |
|---|---|---|---|
| `ar_AE` | Árabe | `ja_JP` | Japonês |
| `cs_CZ` | Tcheco | `ko_KR` | Coreano |
| `da_DK` | Dinamarquês | `nl_NL` | Holandês |
| `de_DE` | Alemão | `pl_PL` | Polonês |
| `el_GR` | Grego | `pt_BR` | **Português (Brasil)** |
| `en_GB` | Inglês | `pt_PT` | **Português (Portugal)** |
| `es_AR` | Espanhol (Argentina) | `ro_RO` | Romeno |
| `es_ES` | Espanhol | `ru_RU` | Russo |
| `fa_IR` | Persa | `sl_SI` | Esloveno |
| `fi_FI` | Finlandês | `sv_SE` | Sueco |
| `fr_FR` | Francês | `tr_TR` | Turco |
| `hr_HR` | Croata | `zh_CN` | **Chinês (simplificado)** |
| `hu_HU` | Húngaro | | |
| `it_IT` | Italiano | | |

> **`zh_CN` (chinês) é o padrão de várias instalações de origem chinesa.** Para português do Brasil, use `pt_BR`.

## Procedimento

### Opção A — script (recomendado)

```powershell
# PowerShell como Administrador
powershell -ExecutionPolicy Bypass -File .\scripts\set_diagbox_language.ps1 -Code pt_BR
```

O script:
1. valida se existe `LAUNCHER<code>.DU8` (evita código inexistente)
2. cria backup `Language.ini.bak` na primeira execução
3. grava `Current=<code>`
4. pede para reiniciar o DiagBox

### Opção B — manual

```powershell
# 1) backup
Copy-Item C:\AWRoot\dtrd\trans\Language.ini C:\AWRoot\dtrd\trans\Language.ini.bak -Force

# 2) editar
notepad C:\AWRoot\dtrd\trans\Language.ini
```

Deixe assim:

```ini
[LANGUAGE]
Current=pt_BR
```

### Aplicar

Feche o DiagBox e rode:

```
C:\AWRoot\bin\launcher\StopAndRelaunch.bat
```

A tela inicial ("Acolhida", "Medidas", "Detecção automática do veículo"…) deve aparecer no idioma escolhido.

## Reverter

```powershell
Copy-Item C:\AWRoot\dtrd\trans\Language.ini.bak C:\AWRoot\dtrd\trans\Language.ini -Force
```

Ou simplesmente rode o script de novo com o código anterior (`-Code zh_CN` para voltar ao chinês).

## Observações

- O arquivo é ASCII simples (`[LANGUAGE]` + `Current=...`); evite salvar como UTF-16.
- `C:\AWRoot\bin\common\Locale.ini` e `Codepage.ini` são **tabelas de mapeamento** (ISO639/codepage), não a configuração ativa.
- `C:\AWRoot\bin\fi\UpdInter.ini` (`LANGUE=FR`) é do atualizador de dicionários, não da interface.
- Se a interface abrir parcialmente traduzida, confira se o `.DU8` do módulo correspondente existe em `dtrd\trans` (instalações incompletas podem ter só parte dos módulos).
