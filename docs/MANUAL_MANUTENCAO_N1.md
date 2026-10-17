# 🛠️ Manual de Operação e Manutenção para o Analista N1 (NOC)

Este manual passo a passo foi preparado especialmente para a equipe de **Operações / NOC (N1 e N2)** realizar a manutenção diária da tela **SGS Links Status - POC** (`UID: adhdb5q`) sem precisar conhecer programação, HTML ou CSS.

---

## 📌 Visão Geral: Como os Links Funcionam

Cada bloco (Card) exibido no Wallboard do NOC é composto por **3 informações**:
1. **Nome Exibido no Card** (no formato `LOCALIDADE - OPERADORA`, ex.: `AMERICANA - HUGHESNET`).
   * Tudo o que vem **antes** do último traço (`-`) vira o título principal em destaque (`AMERICANA`).
   * Tudo o que vem **depois** do último traço (`-`) vira a etiqueta da operadora (`HUGHESNET`).
2. **Nome do Host no Zabbix** (ex.: `[SGS] AMERICANA - INTERNET HUGHESNET`).
3. **Item Monitorado no Zabbix** (*Opcional*):
   * Por padrão, se você deixar em branco ou escrever `ICMP ping`, o painel consulta automaticamente o item **`ICMP ping`** (`1` = `UP`, `0` = `DOWN`).
   * Se for um link monitorado via porta física de Switch/Roteador (como o `L2L VIVO DC - HO`), basta informar o nome exato do item SNMP (ex.: `Interface 1/47(L2L-VIVO-CRS-500MB): Operational status`).

---

## ✅ Método 1: Edição Visual pela Própria Tela (Recomendado — Zero Código)

Na tela da dashboard, no canto superior direito (ao lado do relógio digital), existe um botão discreto **`⚙ N1`**.
*(Na TV do NOC ele fica quase transparente para não poluir o visual, mas no seu computador ele acende ao passar o mouse por cima).*

![Gerenciador Visual N1](../assets/sgs_noc_n1_editor.png)

### 1. Como ADICIONAR um Novo Link WAN
1. Certifique-se de que o host já foi cadastrado no Zabbix (preferencialmente dentro do grupo **`SGS_LINKS`**).
2. Clique no botão **`⚙ N1`** no canto superior direito da dashboard.
3. Na barra superior do gerenciador:
   * **Campo 1 (*Nome no Card*)**: Digite `CIDADE - OPERADORA` (ex.: `RN RODRIGUES - VEGANET`).
   * **Campo 2 (*Host no Zabbix*)**: Comece a digitar o nome do host; o sistema mostrará uma lista automática com todos os hosts do Zabbix. Clique no host desejado (ex.: `[SGS] RN RODRIGUES - INTERNET VEGANET`).
   * **Campo 3 (*Item*)**: Mantenha `ICMP ping` (ou altere apenas se quiser monitorar uma interface SNMP específica).
4. Clique no botão azul **`+ Adicionar Link`**.
5. Clique no botão verde **`💾 Salvar na Dashboard`** no rodapé. Pronto! O card já aparece na tela do NOC imediatamente.

### 2. Como REMOVER um Link Desativado
1. Clique no botão **`⚙ N1`**.
2. Localize o link na lista e clique no botão vermelho **`🗑️ Remover`** na coluna da direita.
3. Clique em **`💾 Salvar na Dashboard`**.

### 3. Como MUDAR o Nome da Unidade ou Trocar a Operadora
1. Clique no botão **`⚙ N1`**.
2. Na tabela, edite diretamente o texto da coluna **Nome Exibido no Card** ou troque o **Nome do Host no Zabbix** (por exemplo, ao substituir `[SGS] RECREIO - INTERNET VIVO` por `[SGS] RECREIO - INTERNET VIVO-NOVO`).
3. Clique em **`💾 Salvar na Dashboard`**.

---

## 📝 Método 2: Edição em Lista de Texto pelo Modo `Edit` do Grafana

Se preferir editar pelo menu nativo do Grafana:

1. Abra a dashboard no Grafana e clique em **Edit** no painel principal.
2. Na barra lateral direita, localize a caixa **Content**.
3. Você verá apenas uma lista limpa em texto puro (1 linha por link):

```text
AMERICANA - HUGHESNET         | [SGS] AMERICANA - INTERNET HUGHESNET
ESTEIO - ALGAR                | [SGS] ESTEIO - INTERNET ALGAR
HIDROMARES - VIVO             | [SGS] HIDROMARES - INTERNET VIVO
SÃO LUIS - VIVO               | [SGS] SÃO LUIS - INTERNET VIVO
BARCARENA - VIVO              | [SGS] BARCARENA - INTERNET VIVO
L2L VIVO DC - HO              | [SGS] - Switch DC CORE - ARUBA | Interface 1/47(L2L-VIVO-CRS-500MB): Operational status
```

* **Para adicionar**: Crie uma nova linha seguindo o padrão `NOME NO CARD | HOST NO ZABBIX`.
* **Para remover**: Apague a linha (ou coloque `#` no início da linha para comentá-la temporariamente).
* **Para salvar**: Clique em **Save dashboard** no topo do Grafana.

---

## ❓ Perguntas Frequentes (FAQ N1)

### 1. O novo link precisa estar no grupo `SGS_LINKS` do Zabbix?
* **Recomendado**: Sim! Mantenha todos os links WAN dentro do hostgroup **`SGS_LINKS`** (`Group ID: 38`) no Zabbix por organização e padronização.
* **Flexibilidade**: Caso você adicione um ativo que esteja em outro grupo (como um Switch Core no grupo `SGS_SWITCHS_DC` ou um host `[SGS]` em grupo regional), o painel também consegue localizá-lo automaticamente pelo prefixo `[SGS]` ou pelo grupo `SGS_LINKS`.

### 2. Se eu adicionar mais links (ex.: passar de 48 para 50 ou 55 links), a tela vai criar barra de rolagem ou cortar na TV do NOC?
* **Não!** O painel usa uma matriz elástica (`grid-auto-rows: 1fr`) travada na proporção exata da TV do NOC (`w = 20, h = 24`). Se você adicionar mais linhas de links, a altura dos cards se ajusta automaticamente em alguns pixels para que todos continuem cabendo 100% dentro da tela única, sem rolagem.
