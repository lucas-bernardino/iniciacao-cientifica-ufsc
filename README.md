# Iniciação Científica - UFSC 
## Esse repósitorio possui o código que desenvolvi para a bolsa de iniciação científica sobre o tema ***Desenvolvimento de atenuador de vibração para motocicletas***

[Objetivos](#objetivo)

[Estrutura do Projeto](#estrutura-do-projeto)

[Tecnologias utilizadas](#tecnologias-utilizadas)

[Como utilizar](#como-utilizar)

![Screenshot1](/assets/screen1.png)

![Screensho2](/assets/screen2.png)


## Objetivos
Esse projeto busca integrar diversos sensores instalados na motocicleta, realizar medições experimentais, analisar os dados coletados e utilizá-los para verificar o desempenho dos atenuadores.

## Estrutura do projeto
Para aquisição de dados, foram utilizados os seguintes sensores:

* ***WitMotion WTGAHRS1***
    * Esse sensor é capaz de disponibilizar aceleração nos três eixos, velocidade angular nos três eixos, orientação angular nos três eixos, campo magnético nos três eixos, latitude e longitude,
    velocidade de acordo com o GPS e pressão atmosférica. Sua comunicação foi feita via **UART**.
* ***Sensor de Àngulo Magnético AS5600***
    * Através desse sensor é possivel obter o esterçamento do guidão da motocicleta. Ele possui 12 bits de resolução e comunicação **I2C**.
* ***Sensor de Efeito Hall***
    * Localizado na roda traseira, ele foi utilizado em junto com um imã para obter a velocidade e rotação da roda. A sua leitura é feita de modo digital.

Para a comunicação com esses sensores, inicialmente foi utilizado a Raspberry Pi Pico. Porém, foi verificada a necessidade de maior processamento de dados, assim passou-se a utilizar a **Raspberry Pi 4**.

Antes de iniciar a acquisição, deve-se ter disponibilidade de Wi-Fi e um dispositivo que tenha a capacidade de se comunicar por Secure Socket Shell (*SSH*) para inicializar o código. Após o programa ter sido inicializado, a aquisição de dados pode ser feita de modo offline, salvando os dados localmente na Raspberry e posteriormente visualizando-os em um computador ou salvando os dados em um banco de dados e visualizando-os em tempo real em um site.

## Tecnologias utilizadas
1. Acquisição e comunicação com os sensores
    - O código responsável pela acquisição e comunicação com os sensores foi desenvolvido em **Python**. A escolha dessa linguagem deve-se ao fato de ser relativamente simples utilizá-la para trabalhar com *threads*, haja visto a necessidade de utilizá-las para trabalhar de modo concorrente, melhorando a eficiência e perfomance do código. Ela também possui simplicidade para a comunicação com os sensores, permitindo uma eficaz leitura e escrita com os protocolos *I2C* e *UART*.

    - Devido ao fato de ser uma linguagem interpretada, ela pode ser mais lento em algumas tarefas em relação a linguagens compiladas como **C**. Porém, não foi verificado perda de perfomance nessas tarefas.

    - Além disso, foi utilizado o *Python* para limpar e tratar os dados recebidos, criando a possibilidade de facilmente transformar os dados salvos em txt para planilhas visíveis em *Excel* ou *LibreOffice*. Quando há Wi-Fi, existe também um backend utilizando o framework **Flask** para enviar os arquivos da planilha que estão no formato *csv* para o frontend. Essa parte pode ser considerada um microserviço, visto que consome os dados salvos na **API** do backend feito em **NodeJs** e expõe novas rotas que serão utilizadas pelo frontend para visualizar e baixar a planilha. 

2. Servidor e banco de dados
    - Quando há possibilidade de visualizar os dados em tempo real, o código construido em *Python* se comunica com um servidor feito em *NodeJs* com o framework Express. Foi desenvolvida uma *API* para que toda vez que houver um novo pacote de dados, o código em Python envia os dados para o backend em *NodeJS*, que por sua vez salva esses dados no banco de dados. O banco de dados utilizados foi o **MongoDB**, devido a não necessidade de se utilizar um banco relacional para esse trabalho.

    - A *API* possui diversas rotas que são tanto utilizadas pelo *Python* para a *API*, como também pelo frontend, que faz uma requisição para exibir esses dados formatados ao cliente.

3. Frontend
    - O usuário pode visualizar os dados, observar o gráfico deles em tempo real ao longo do tempo e baixar os dados em uma planilha de formato *csv* através da página construída utilizando a biblioteca **React** utilizando o **Typescript**. Ela está constantemente fazendo requisições para a *API* feita em *NodeJs* e também ocasionamente faz requisições para a *API* feita em *Flask* para baixar a planilha em *csv*.

4. **Docker** e Deploy
    - O frontend e backend são inicializados através de containers que rodam na própria Raspberry Pi 4, utilizando o *Docker*. Como nem sempre a rede de Wi-Fi utilizada pela Raspberry será a mesma que o cliente visualizará a página, foi utilizado o **Ngrok**, que permite expor os serviços que estão sendo executados localmente para a Internet. Porém, como foi utilizado o free-tier do Ngrok, apenas 20000 requisições podem ser feitas por mês.

## Como utilizar

Para iniciar o projeto, é necessário instalar algumas dependências:
1. Verifique se há novas atualizações e instale-as.
```
sudo apt-get update && sudo apt-get upgrade
```

2. Instale dependências internas.
```
sudo apt-get install build-essential tk-dev libncurses5-dev libncursesw5-dev libreadline6-dev libdb5.3-dev libgdbm-dev libsqlite3-dev libssl-dev libbz2-dev libexpat1-dev liblzma-dev zlib1g-dev libffi-dev    
```

3. *Python*.
```
# Primeiro, verifique se o python já está instalado:
python --version

# Caso não tenha instalado, instale-o:
sudo apt install python3
```

4. Caso possua Wi-Fi disponível no trajeto e queira visualizar os dados em tempo real, é necessário utilizar o *Docker* para subir os containers do backend e frontend
```
# Passos para instalar o Docker na Raspberry Pi, seguindo a documentação oficial https://docs.docker.com/engine/install/raspberry-pi-os/

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/raspbian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Set up Docker's APT repository:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/raspbian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install the Docker packages.
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# É preciso adicionar o usuário atual no grupo do Docker, para que tenha permissões de usar o Docker:
sudo usermod -aG docker ${USER}

# Instale, também, o Docker-Compose
# Verifique se python3 e pip3 já estão instalados
sudo apt-get install libffi-dev libssl-dev
sudo apt install python3-dev
sudo apt-get install -y python3 python3-pip

# Instale o Docker-Compose
sudo pip3 install docker-compose

# Habilite o *Docker system service* sempre que ocorra um boot na Raspberry
sudo systemctl enable docker
```

5. Para acessar as URLs do site, é preciso ter o *Ngrok* instalado. Como dito anteriormente, ele cria um tunel de conexão entre o localhost e a Internet
```
# Faça o download do Ngrok
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.tgz

# Extraia o arquivo baixado para o PATH
sudo tar xvzf ./ngrok-v3-stable-linux-arm64.tgz -C /usr/local/bin

# Você precisa ter uma conta criada no Ngrok. Após isso, substitua NGROK_AUTHTOKEN pelo seu token gerado. Você encontra o token na dashboard do site Ngrok
ngrok authtoken NGROK_AUTHTOKEN
```
6. Configurando *Ngrok*
```
# Após ter instalado o ngrok, você deve ter um arquivo de configuração que será usado para subir três tuneis (backend, frontend e flask no python) ao subir os # # containers

# Navegue para o arquivo de configurações do ngrok
cd ~/.config/ngrok && ls -al

# Caso não haja nenhum arquivo nessa pasta, crie-o
touch ngrok.yml

# Abra o arquivo 
sudo nano ngrok.yml

# Cole a seguinte configuração nesse arquivo, substituindo <AUTH_TOKEN> pelo seu token do ngrok
version: "2"
authtoken: <AUTH_TOKEN>
tunnels:
  backend:
    addr: 3001
    proto: http
  frontend:
    addr: 5173
    proto: http
  flask:
    addr: 5000
    proto: http
```

7. Clone o repositório
```
git clone https://github.com/lucas-bernardino/iniciacao-cientifica-ufsc.git
```

8. Iniciando o projeto sem Wi-Fi disponível no percurso da acquisição dos dados
```
# Após ter clonado o repositório, entre na pasta contendo o código que inicia a acquisição dos dados
cd iniciacao-cientifica-ufsc/codigo_rasppi4/sem_internet

# Inicialize o programa
python3 sem_net.py
```
-   Você deve apertar o botão físico para começar a salvar os dados. Após ter terminado o a acquisição e estar pronto para visualiza-los, você pode sair do programa com *Ctrl-C*. Estarão enumerados vários arquivos *txt* nessa pasta, que foram os dados obtidos através da acquisição. Para transformar esses dados em uma planilha *csv*, rode o seguinte comando:
    ```
    # No mesmo diretório em que estão os arquivos *txt*, rode:
    python3 limpar_dados.py
    
    # Verifique o IP da Raspberry Pi 4. Copie o primeiro elemento da lista de IPs que aparecerão.
    hostname -I

    # Verifique o diretório em que você está
    pwd
    ```

-   Agora, no computador que você quer transferior os dados:
    ```
    # Vá para o diretório no qual deseja transferir os arquivos, ou crie uma pasta
    mkdir dados_recebidos

    # Navegue para o diretório, caso tenha criado a pasta acima
    dir dados_recebidos

    # Por padrão, os dados salvos na Raspberry são do tipo dados0.csv, dados1.csv, dados2.csv ...
    # Assim, você deve executar o próximo comando substituindo o em <NOME-DO-ARQUIVO-RASP> o arquivo correspondente na 
    # Raspberry. Um exemplo seria: 
    # scp pi@192.168.0.1:/home/pi/iniciacao-cientifica-ufsc/codigo_rasppi4/sem_internet/dados0.csv primeiro_teste.csv

    scp pi@<IP-DA-RASPBERRY>:<DIRETORIO-MOSTRADO-NO-PWD>/<NOME-DO-ARQUIVO-RASP> <NOME-DO-NOVO-ARQUIVO>.csv
    ```
    Após isso, o arquivo já estára disponível para ser visualizado no computador

9. Iniciando o projeto com Wi-Fi disponível no percurso da acquisição dos dados
```
# Após ter clonado o repositório, entre na pasta do repositório
cd iniciacao-cientifica-ufsc
```
- Há um **bash script** que automatiza a inicialização da aplicação. Ele inicia os serviços e cria os tuneis do *Ngrok* e roda um script em **Rust** que seta as váriaves de ambiente *.env* com as novas URls geradas randomicamentes pelo *Ngrok*. Após setar tais variáveis, é subido o container e inicializado a aplicação.
  ```  
  # Para rodar o script em Rust, primeiro instale-o
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

  # Verifique se foi instalado com sucesso
  rustc –version
  cargo –version

  # Antes de rodar o script, talvez você precise fornecer autorização para executá-lo
  sudo chmod +x start.sh

  # Após ter permissão, rode
  ./start.sh
  ```
  Preste atenção no output desse script. Antes de subir o container, o código em *Rust* exibirá todas as URLs geradas pelo *Ngrok*. Você pode acessar o site para visualizar os dados em tempo real copiando a URL do *FRONTEND ROUTE* que aparecerá no console.

- Após ter subido o container, basta navegar para a pasta do código em python que envia os dados para o servidor para iniciar a acquisição de dados
  ```
  # Navegue até o diretório do código em python
  cd iniciacao-cientifica-ufsc/com_internet

  # Inicie o programa
  python3 main.py
  ```
  Após ter iniciado o código em *Python*, você já pode acompanhar os dados em tempo real no site cuja URL foi exibida anteriormente no console
  
