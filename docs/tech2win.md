# Autel J2534 no Tech2Win (GM)

Como fazer um adaptador **J2534** (testado: Autel MaxiVCI V200) ser reconhecido pelo **Tech2Win 2.302** (emulador Tech2 da GM) em Windows 64 bits.

> Referência testada: DiagBox 09.85 + Autel MaxiVCI V200 (USB, DLL `VCIV200432.dll` 2.0.2.1, FW `V0.2c.0`) — ver [`versoes.md`](versoes.md). Tech2Win **2.302**, Windows 11 Pro 10.0.26300 x64.

## Como o Tech2Win escolhe a VCI

O Tech2Win **não lê o registro J2534 diretamente** — ele usa a **D-PDU API (ISO 22900-2)**:

1. Lê o root file registrado em
   `HKLM\SOFTWARE\WOW6432Node\D-PDU API` → valor **`Root File`**
   (normalmente `C:\Program Files (x86)\D-PDU API\pdu_api_root.xml`).
2. Cada `<MVCI_PDU_API>` desse XML é uma "API de fabricante" que aparece na caixa
   **"Selecionar Interface de comunicação do veículo"**.
3. Ao escolher uma API, o Tech2Win carrega a DLL e lista os dispositivos (recursos) que ela reporta.

No `.conf` de cada configuração existem duas opções (documentadas no help):

```ini
-Pp   ; ISO22900-2 / PDU-API (padrão)
-Pj   ; "J2534" (na prática o Tech2Win 2.302 continua usando a D-PDU API)
```

### O problema com a API D-PDU da Autel

O Maxi PC Suite instala uma D-PDU API própria:

```
C:\ProgramData\AUTEL_DPDU_API\D_PDU_API.dll
```

Ela aparece na lista como **"AUTEL, D-PDU API by AUTEL"** e carrega normalmente, mas
**não enumera o V200** — o log termina com `pdu_api.c ... No VCI selected` e a lista de dispositivos fica vazia.

Além disso, os cartões PCMCIA não trazem suporte a adaptadores fora da linha GM.

## Solução: dpdu-passthru (D-PDU → J2534)

Projeto open-source **GPL-3.0** que cria uma D-PDU API em cima de qualquer DLL J2534 registrada em `PassThruSupport.04.04`:

- https://github.com/JohnJocke/dpdu-passthru (release usada: **v0.7.0**)
- Testado pelo autor com Tech2Win + adaptadores J2534 (K-line/CAN)
- Instalação ~40 KB: `driver.dll`, `pdu_api_root.xml`, `dpdu_settings.ini`, `pdu.reg`, `install.bat`

### Instalação seletiva (recomendada)

O `install.bat` original **sobrescreve** o `pdu_api_root.xml` (perderia as entradas AUTEL/Bosch MDI). Faça o merge manual:

1. **Backup** do root atual:
   ```powershell
   Copy-Item "C:\Program Files (x86)\D-PDU API\pdu_api_root.xml" "C:\AWRoot\backup_J2534\pdu_api_root.xml.bak" -Force
   ```
2. Copie o driver:
   ```powershell
   New-Item -ItemType Directory -Force "C:\Program Files (x86)\dpdu_j2534" | Out-Null
   Copy-Item .\driver.dll "C:\Program Files (x86)\dpdu_j2534\driver.dll" -Force
   Copy-Item .\dpdu_settings.ini "C:\Users\Public\dpdu_settings.ini" -Force
   ```
3. Adicione a entrada ao **root XML existente** (dentro de `<MVCI_PDU_API_ROOT>`):
   ```xml
   <MVCI_PDU_API>
       <SHORT_NAME>DPDU_J2534</SHORT_NAME>
       <DESCRIPTION>D-PDU-to-J2534 Implementation</DESCRIPTION>
       <SUPPLIER_NAME>github.com/JohnJocke</SUPPLIER_NAME>
       <LIBRARY_FILE URI="file:///C:/Program Files (x86)/dpdu_j2534/driver.dll" />
   </MVCI_PDU_API>
   ```
4. Garanta o registry:
   ```
   HKLM\SOFTWARE\WOW6432Node\D-PDU API
       Root File = C:\Program Files (x86)\D-PDU API\pdu_api_root.xml
   ```
5. Reinicie o Tech2Win.

### Seleção

1. Inicie uma configuração no Tech2Win.
2. Em **"Selecionar fabricante"**, escolha **`D-PDU-to-J2534 Implementation`**
   (aparece junto de AUTEL, GM MDI e GM MDI 2).
3. Na lista de dispositivos, escolha o adaptador Autel.
4. O Tech2Win exibirá o aviso **E675228** ("dispositivo de comunicação não validado") — é **esperado** para VCI fora da linha GM. Clique **OK** e continue.

## Verificação

Log em `C:\Users\Public\General Motors\Tech2Win\Logs\*.html`:

```
xml.c ... XML DOM found VCI DLL: 'C:\Program Files (x86)\dpdu_j2534\driver.dll'
pdu_api.c ... Selected Manufacturer: 'D-PDU-to-J2534 Implementation'
```

## Ajustes (`C:\Users\Public\dpdu_settings.ini`)

```ini
[Settings]
DisableTesterpresent=0
FixTesterpresentDestination=1
AutoRestartComm=1
```

- `DisableTesterpresent=1` desativa o envio de mensagens tester-present
- `FixTesterpresentDestination=1` corrige destino das mensagens
- `AutoRestartComm=1` reinicia a comunicação automaticamente

## Observações

- O **nome exibido** do adaptador vem do valor `Name` da chave J2534. O V200 original registra `Name=1B` (pouco amigável); pode-se criar uma chave alias com nome legível (ex.: `MX2` → `Autel MaxiVCI V200 (MX2)`) sem alterar a original.
- A opção `-Pj` nos `.conf` não é obrigatória — o Tech2Win 2.302 usa a D-PDU API de qualquer forma. `-Pp` é o padrão documentado.
- **Idioma:** o Tech2Win segue o Windows (ou `-L PB` / `-L PT` no `.conf`); a tela azul do Tech2 é o software do cartão PCMCIA e só muda com download TIS no idioma desejado.

## Reversão

```powershell
# restaurar root XML
Copy-Item "C:\AWRoot\backup_J2534\pdu_api_root.xml.bak" "C:\Program Files (x86)\D-PDU API\pdu_api_root.xml" -Force

# remover driver/instalação (opcional)
Remove-Item "C:\Program Files (x86)\dpdu_j2534" -Recurse -Force
```

## Limitações

- Validado o reconhecimento/seleção da VCI no Tech2Win; a comunicação com módulos do veículo depende do carro GM, dos protocolos (K-line/CAN) e do cartão PCMCIA correto.
- O projeto dpdu-passthru é de terceiros (GPL-3.0) — instale por sua conta e risco; os binários não são distribuídos neste repositório.
