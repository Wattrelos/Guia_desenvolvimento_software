# Models of e-mails to send to abuse departments of hosting providers

> Aqui está um modelo de e-mail em inglês, direto e profissional, pronto para você enviar ao departamento de abuso (abuse@) do provedor de hospedagem.
Lembre-se de substituir os textos entre colchetes [ ] pelas suas informações reais e colar trechos dos logs do seu servidor (como o access.log ou registros de um plugin de segurança como Wordfence).
Subject: Abuse Report: WordPress Vulnerability Exploitation / Brute Force Attempts from [IP_DO_ATACANTE]
```text
Hello Abuse Team,

I am writing to report malicious activity originating from an IP address belonging to your network ([IP_DO_ATACANTE]).
We have detected automated attempts targeting our WordPress installation, specifically probing for known vulnerabilities, attempting unauthorized access, and scanning sensitive files (e.g., wp-login.php, xmlrpc.php, or vulnerable plugins).
Incident Details:
• Attacker IP: [IP_DO_ATACANTE]
• Target Domain/IP: [SEU_DOMINIO_OU_IP]
• Date & Time (with Timezone): [DATA_E_HORA_COM_FUSO_HORARIO, ex: 2026-11-19 17:15:00 UTC-3]
• Activity Type: WordPress Vulnerability Scanning / Brute Force / Exploitation Attempts
Relevant Server Logs:
text
[COLE AQUI 5 A 15 LINHAS DO LOG MOSTRANDO O IP, DATA, HORA E A URL REQUISITADA]
Use o código com cuidado.
Please investigate this matter and take appropriate action in accordance with your Acceptable Use Policy (AUP) to stop this malicious traffic.
Thank you for your time and assistance.
Best regards,
[SEU_NOME]
[SEU_CARGO_OU_EMPRESA - Opcional]
[SEU_EMAIL_DE_CONTATO]
```

## Dicas rápidas antes de enviar:

• Inclua o fuso horário: Equipes de abuse geralmente ficam em outros países e precisam do fuso horário (ex: UTC-3 ou GMT-3) para cruzar os horários com os registros internos deles.
• Não envie arquivos enormes: Cole apenas as linhas mais relevantes no corpo do e-mail (entre 5 e 15 linhas). Se tiver centenas de tentativas, anexe um arquivo .txt simples.
