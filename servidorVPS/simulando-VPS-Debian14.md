# Servidor VPS com Debian 14

 Este tutorial mostra como simular um servidor VPS. Cenário ideal para teste de sistema antes de ir para a produção.
 
Durante a instalação, você deve desmarcar todas as opções na tela de seleção de software (tasksel) e deixar apenas o servidor SSH marcado.
A maioria dos provedores de nuvem fornece imagens mínimas do Debian que contêm apenas o sistema base e o acesso remoto. Manter o ambiente enxuto economiza memória RAM, espaço em disco e reduz a superfície de ataque.

Como configurar as opções na instalação

Durante o passo Seleção de software do instalador do Debian (inclusive nas versões de teste/testing como o Debian 14 Forky), ajuste as caixas da seguinte forma:
• Ambiente de área de trabalho Debian (e GNOME, XFCE, etc.): Desmarque. Servidores VPS são gerenciados via terminal e não possuem interface gráfica por padrão.
• Servidor web: Desmarque. É melhor instalar o Nginx ou Apache manualmente depois, conforme a necessidade do seu projeto.
• Servidor de impressão: Desmarque. Totalmente desnecessário em um ambiente de nuvem.
• Servidor SSH: Marque. Este é o componente essencial que permite acessar e administrar o servidor remotamente pela rede.
• Utilitários padrão do sistema: Opcional (pode desmarcar). Esse pacote instala ferramentas comuns de linha de comando (como wget, bash-completion, less, man). Em VPS reais, muitas vezes até isso vem desmarcado para manter a imagem mínima, mas você pode deixar marcado se quiser ter comandos básicos prontos para uso sem precisar instalá-los via apt depois.

Dica extra para a simulação

Após concluir a instalação, lembre-se de configurar a placa de rede da sua máquina virtual em Modo Bridge (ou configurar o redirecionamento de portas no modo NAT). Isso permitirá que você acesse a VM pelo terminal do seu computador principal usando o comando ssh usuario@ip-da-vm, exatamente como faria com um servidor contratado na internet.

Sim, a primeira coisa é atualizar o sistema e garantir o acesso via SSH para que você possa sair do console da VM e trabalhar pelo terminal do seu computador.
Como você acabou de instalar uma versão mínima, o fluxo ideal simula exatamente os primeiros minutos de configuração de um servidor VPS real.

1. Atualize os pacotes e instale o sudo

Faça login como root no console da VM e rode os comandos abaixo para atualizar o sistema e instalar o pacote sudo (que não vem pré-instalado em instalações mínimas do Debian):
bash
apt update && apt upgrade -y
apt install sudo curl wget vim -y
Use o código com cuidado.
• Adicione seu usuário ao grupo sudo: Substitua seu_usuario pelo nome que você criou na instalação com o comando usermod -aG sudo seu_usuario.

2. Verifique o IP e conecte via SSH

Como você marcou o SSH na instalação, o serviço já deve estar rodando. Descubra o IP da sua VM para poder acessá-la externamente:
• Descobrir o IP: Digite ip -c a e anote o endereço IPv4 (geralmente começa com 192.168... ou 10.0... se estiver em Modo Bridge).
• Conectar do seu PC: Abra o terminal do seu computador principal (Windows Terminal, PowerShell, Linux ou macOS) e conecte usando ssh seu_usuario@IP_DA_VM. A partir daqui, você não precisa mais usar a janela da VM.

3. Proteja o acesso SSH (Padrão VPS)

Em um servidor real exposto na internet, você nunca deve deixar o login como root ou por senha totalmente abertos. Configure o acesso por chave criptográfica:
• Envie sua chave pública: No terminal do seu computador (não na VM), rode ssh-copy-id seu_usuario@IP_DA_VM (se não tiver uma chave, gere antes com ssh-keygen -t ed25519).
• Desative o login direto de root: Já conectado na VM, edite o arquivo /etc/ssh/sshd_config (sudo vim /etc/ssh/sshd_config), altere a linha PermitRootLogin para PermitRootLogin no e reinicie o serviço com sudo systemctl restart ssh.

4. Ative um Firewall básico

Por fim, feche todas as portas de entrada, liberando apenas o SSH (e futuramente HTTP/HTTPS se for hospedar sites). O UFW é o padrão mais simples e usado em tutoriais de VPS:
bash
sudo apt install ufw -y
sudo ufw allow OpenSSH
sudo ufw enable
Use o código com cuidado.
Com esses quatro passos concluídos, sua VM estará idêntica a uma VPS recém-contratada e segura na nuvem, pronta para receber Docker, servidores web ou bancos de dados.

## Preparando o servidor para hospedar o Rust

[Tutorial para instalar o servidor Nginx](https://github.com/Wattrelos/Tutoriais/blob/main/web-servers/nginx-instalacao.md)
[MariaDB](https://github.com/Wattrelos/Tutoriais/blob/main/databases/SQL-D/mariadb-instalacao.md)
[Redis](https://github.com/Wattrelos/Tutoriais/blob/main/databases/Key-value-database/redis-instalacao.md)
[MongoDB](https://github.com/Wattrelos/Tutoriais/blob/main/databases/documents-oriented-db/mongodb-server-instalacao.md)




