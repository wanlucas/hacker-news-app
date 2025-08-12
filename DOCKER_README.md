# Executando a Aplicação com Docker

Esta aplicação consiste em um backend Rails e um frontend Vue.js que podem ser executados usando Docker Compose.

## Pré-requisitos

- Docker
- Docker Compose

## Como executar

1. **Clone o repositório e navegue até a pasta raiz:**

2. **Construa e execute os containers:**
   ```bash
   docker-compose up --build
   ```

3. **Para executar em background:**
   ```bash
   docker-compose up -d --build
   ```

## Acessando a aplicação

- **Frontend (Vue.js):** http://localhost:5173
- **Backend (Rails API):** http://localhost:3000
- **WebSocket:** ws://localhost:3000/websocket

## Configurações

### CORS
O CORS está configurado para permitir todas as origens (`*`) no modo de desenvolvimento. Para produção, certifique-se de configurar origens específicas no arquivo `server/config/initializers/cors.rb`.

### WebSocket
O Action Cable (WebSocket) também está configurado para aceitar conexões de qualquer origem no modo de desenvolvimento.

### Volumes
Os arquivos são montados como volumes, então as alterações no código são refletidas automaticamente nos containers sem necessidade de rebuild.
