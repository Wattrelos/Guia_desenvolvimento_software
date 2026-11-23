# AbuseIPDB Report Form

> **Original Prompt (English):**
> By submitting this form, you understand that your reports carry weight and thus you will report responsibly. Your reports can be removed at any time for any reason, without notice. Misreporting will result in suspension of this privilege. You have also read and understood the AbuseIPDB reporting policy.
>
> Describe the following:
> - Your organization (if any), role, and background
> - Infrastructure details, such as servers, networks, and security measures you manage or are involved with
> - The nature of activity you plan to report (e.g. brute force attacks, phishing, malware distribution)

---

## Tradução das Instruções e Requisitos

Ao enviar este formulário, você declara compreender que suas denúncias têm peso na reputação de endereços IP e que atuará de forma responsável. Seus relatórios podem ser removidos a qualquer momento, por qualquer motivo, sem aviso prévio. Denúncias incorretas ou abusivas (*misreporting*) resultarão na suspensão desse privilégio. Você também confirma que leu e compreendeu a política de denúncias (*reporting policy*) do AbuseIPDB.

Descreva os três pontos abaixo:
1. **Sua organização (se houver), função e histórico/experiência** (*Your organization, role, and background*)
2. **Detalhes da infraestrutura**, como servidores, redes e medidas de segurança que você gerencia ou com as quais trabalha (*Infrastructure details*)
3. **A natureza das atividades que pretende reportar**, como ataques de força bruta, phishing, distribuição de malware, etc. (*The nature of activity you plan to report*)

---

## Rascunho Revisado (Português)

> **Ajustes feitos em relação ao rascunho original:**
> - Correção ortográfica (`consultaria` → `consultoria`) e eliminação de repetições (`Tenho experiência em...`).
> - Inclusão explícita do **item 2 (Detalhes da Infraestrutura)**, que estava ausente no rascunho inicial.
> - Reforço técnico na diferenciação de robôs legítimos: além de *User-Agent* e padrões de requisição, incluí **validação por DNS reverso (FCrDNS) e faixas oficiais de IP**, pois avaliadores do AbuseIPDB sabem que *User-Agent* pode ser facilmente falsificado.

### 1. Organização, Função e Experiência
Sou estudante e pesquisador na área de Segurança da Informação, atuando também com consultoria independente para pequenas e médias empresas, auxiliando na proteção de seus sistemas e dados contra ameaças cibernéticas. Além disso, participo de projetos de pesquisa acadêmica voltados ao desenvolvimento de novas técnicas de detecção e prevenção de intrusões (IDS/IPS). Possuo experiência prática em análise de logs, detecção de padrões suspeitos, avaliação e exploração controlada de vulnerabilidades, além de análise e engenharia reversa de malware.

### 2. Detalhes da Infraestrutura
Gerencio e monitoro servidores Linux (VPS) voltados à hospedagem de aplicações web e APIs, além de apoiar ambientes de rede de clientes de consultoria. A infraestrutura conta com firewalls baseados em host (UFW/iptables), prevenção automatizada de intrusões com Fail2ban, proxies reversos (Nginx) com filtragem de requisições e pipelines dedicados para triagem e correlação de logs do sistema operacional e da camada HTTP.

### 3. Natureza das Atividades a Reportar e Prevenção de Falsos Positivos
Pretendo reportar exclusivamente atividades maliciosas recorrentes e verificadas, incluindo tentativas de força bruta em SSH e serviços expostos, varreduras agressivas de portas e reconhecimento automatizado de vulnerabilidades na camada web (como hosts enviando múltiplas requisições `GET`/`POST` em busca de arquivos `.env`, `/wp-login.php` ou painéis administrativos inexistentes).

Para evitar falsos positivos, aplico filtros rigorosos antes de qualquer denúncia: utilizo listas de exclusão (*allowlists*) para infraestrutura legítima e verifico *crawlers* conhecidos (como Googlebot e Bingbot) por meio de **DNS reverso confirmado (FCrDNS)** e faixas de IP oficiais — nunca confiando apenas no cabeçalho `User-Agent`, que pode ser forjado. Todas as ocorrências são avaliadas por limiares de frequência/rajada e acompanhadas de evidências reais de log com carimbo de data/hora em UTC.

---

## Texto Final para Envio (English — Ready to Submit)

> Copie e cole o texto abaixo diretamente no formulário do AbuseIPDB (revise eventuais detalhes de infraestrutura entre colchetes ou ajuste conforme o seu ambiente real):

```text
1. Organization, Role, and Background:
I am an Information Security student and researcher, and I also provide independent security consulting for small and medium-sized businesses, helping them protect their systems and data against cyber threats. Additionally, I participate in academic research projects focused on developing new intrusion detection and prevention techniques (IDS/IPS). My background includes hands-on log analysis, suspicious traffic pattern detection, vulnerability assessment, and malware analysis/reverse engineering.

2. Infrastructure Details:
I manage and monitor Linux VPS servers hosting web applications and APIs, as well as small client environments under my consultancy. These systems are protected by host-based firewalls (UFW/iptables), Fail2ban for automated brute-force mitigation, reverse proxies (Nginx) with strict request filtering, and automated log-triage scripts that correlate kernel firewall blocks and authentication failures using UTC timestamps.

3. Nature of Activity Planned to Report & False-Positive Prevention:
I plan to report verified, persistent malicious activity targeting our infrastructure, primarily:
- SSH and service brute-force attacks (confirmed via Fail2ban bans and sustained connection bursts);
- Aggressive port scanning against administrative and database ports;
- Automated web vulnerability probing and exploit scanning (e.g., hosts sending repeated GET/POST requests probing for .env files, /wp-login.php, or exposed configuration endpoints).

To prevent false positives and ensure high-quality reports, all events undergo automated and manual filtering before submission. We maintain allowlists for known legitimate infrastructure and verify search engine crawlers (such as Googlebot and Bingbot) using Forward-Confirmed Reverse DNS (FCrDNS) and official published IP ranges rather than relying solely on spoofable User-Agent headers. Only hosts exceeding clear frequency thresholds—backed by raw, UTC-timestamped log evidence—will be reported in full compliance with the AbuseIPDB reporting policy.
```
