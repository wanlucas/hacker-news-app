# Hacker News Real-time Client

Uma aplicação full-stack moderna que consome a API do Hacker News com cache inteligente, atualizações em tempo real via WebSocket e interface Vue.js responsiva.

## 🚀 Como Iniciar a Aplicação

### Pré-requisitos

- Docker e Docker Compose

### 🔧 Instalação e Execução

#### Usando Docker (Recomendado)

```bash
# Clone o repositório
git clone <repository-url>
cd bee

# Inicie a aplicação completa
docker-compose up

# Para rebuild após mudanças
docker-compose up --build
```

**URLs de Acesso:**
- Frontend (Vue.js): http://localhost:5173
- Backend API (Rails): http://localhost:3000
- API Endpoints: http://localhost:3000/api/stories

#### Execução Local (Desenvolvimento)

**Backend (Rails):**
```bash
cd server

bundle install
rails server -p 3000
```

**Frontend (Vue.js):**
```bash

npm install
npm run dev
```

### 🌍 Variáveis de Ambiente

#### Frontend (Client)

VITE_SOCKET_URL=ws://localhost:3000/cable
VITE_API_URL=http://localhost:3000
VITE_DEBUG=true


#### Backend (Server)

CLIENT_URL=http://localhost:5173

## 🏗️ Arquitetura da Aplicação

### 📋 Visão Geral

A aplicação segue uma arquitetura limpa com separação clara de responsabilidades, implementando patterns de design sólidos e práticas modernas de desenvolvimento.

```
┌─────────────────┐    WebSocket     ┌──────────────────┐
│   Vue.js Client │◄──────────────────┤  Rails API       │
│                 │                   │                  │
│ • Components    │    HTTP API       │ • Controllers    │
│ • Composables   │◄──────────────────┤ • Services       │
│ • Services      │                   │ • Jobs           │
└─────────────────┘                   │ • Channels       │
                                      └──────────────────┘
                                               │
                                      ┌──────────────────┐
                                      │  Hacker News API │
                                      │                  │
                                      │ • Stories        │
                                      │ • Comments       │
                                      │ • Items          │
                                      └──────────────────┘
```

### 🎯 Backend (Rails API)

#### 🔗 Injeção de Dependências

A aplicação utiliza um **Service Factory** para gerenciar dependências de forma limpa:

```ruby
# app/services/service_factory.rb
class ServiceFactory
  def self.hacker_news_service
    HackerNewsService.new(
      http_client: HttpClient.new('https://hacker-news.firebaseio.com/v0'),
      cache_repository: Repositories::Cache::Rails.new,
      broadcasting_service: BroadcastingService.new,
      logger: Rails.logger
    )
  end
end
```

**Vantagens:**
- ✅ Baixo acoplamento entre componentes
- ✅ Fácil substituição de dependências para testes
- ✅ Configuração centralizada
- ✅ Facilita mocking em testes unitários

#### 🎨 Repository Pattern

Implementação do padrão Repository para abstração do cache:

```ruby
# Abstração base
class Repositories::Cache::Base
  def read(key); end
  def write(key, value, options = {}); end
  def exist?(key); end
  def delete(key); end
end

# Implementação Rails
class Repositories::Cache::Rails < Base
  # Implementação usando Rails.cache
end
```

**Benefícios:**
- ✅ Abstração da camada de persistência
- ✅ Facilita troca de engines de cache
- ✅ Testabilidade melhorada
- ✅ Separação de responsabilidades

#### 💾 Sistema de Cache Inteligente

A aplicação implementa uma estratégia de cache com **Stale-While-Revalidate**:

```ruby
# app/lib/cached_api.rb
class CachedApi
  def load_cache(key, revalidate_fn:)
    data = @cache_repository.read(key)

    # Retorna cache válido imediatamente
    return data if cache_is_valid?(key)

    if data.nil?
      # Cache miss - busca dados fresh
      data = revalidate_fn.call
    elsif !@cache_repository.exist?("#{key}_lock")
      # Cache stale - atualiza em background
      background_refresh(key, revalidate_fn)
    end

    data
  end
end
```

**Características:**
- 🚀 **Performance**: Retorna dados em cache instantaneamente
- 🔄 **Freshness**: Atualiza dados em background quando stale
- 🔒 **Concorrência**: Lock mechanism previne múltiplas atualizações
- ⚡ **Graceful Degradation**: Continua servindo cache stale se API falhar

#### 🔄 Jobs Assíncronos e Worker Periódico

**Job de Atualização:**
```ruby
# app/jobs/stories_update_job.rb
class StoriesUpdateJob < ApplicationJob
  def perform
    ServiceFactory.hacker_news_service.update_cache
  end
end
```

**Worker Periódico:**
```ruby
# config/initializers/periodic_jobs.rb
Thread.new do
  loop do
    StoriesUpdateJob.perform_now
    sleep 5.minutes
  end
end
```

**Benefícios:**
- ⏰ Atualizações automáticas a cada 5 minutos
- 🔄 Mantém cache sempre atualizado
- 📊 Broadcast de novos dados via WebSocket

#### 🌐 HTTP Client Robusto

```ruby
# app/services/http_client.rb
class HttpClient
  def get(endpoint)
    # Implementação com tratamento de erros
    # Logging detalhado
    # Parsing JSON automático
  end
end
```

**Features:**
- 🔍 Logging detalhado de requests
- ⚠️ Error handling customizado
- 🔄 Retry logic implícito
- 📊 Debugging tools integrados

#### ⚡ Paralelização Inteligente

O serviço utiliza **threading** para otimizar fetching de dados:

```ruby
# Busca stories em paralelo (batches de 10)
ids.each_slice(10) do |batch|
  threads = batch.map do |id|
    Thread.new { fetch_story(id) }
  end
  threads.each(&:join)
end

# Busca comments em paralelo (batches de 30)
ids.each_slice(30) do |batch|
  threads = batch.map do |id|
    Thread.new { fetch_comment(id) }
  end
end
```

**Vantagens:**
- 🚀 Redução significativa de latência
- 📊 Throughput otimizado
- 🔒 Thread-safe com Mutex
- ⚖️ Load balancing automático

#### 📡 WebSocket Real-time

```ruby
# app/channels/stories_channel.rb
class StoriesChannel < ActionCable::Channel::Base
  def subscribed
    stream_from "stories_updates"
  end

  def self.broadcast_new_stories(stories)
    ActionCable.server.broadcast('stories_updates', {
      type: 'new_stories',
      data: stories
    })
  end
end
```

## 🧪 Testes Automatizados

### 📋 Estrutura de Testes

```ruby

# test/services/hacker_news_service_test.rb
class HackerNewsServiceTest < ActiveSupport::TestCase
  def setup
    @http_client = mock_http_client
    @cache_repository = mock_cache_repository
    @broadcasting_service = mock_broadcasting_service
    @logger = mock_logger
  end

  test "should return stories from cache when valid" do
    # Testa comportamento de cache válido
  end

  test "should fetch fresh data on cache miss" do
    # Testa cache miss scenario
  end
end
```

**Cobertura de Testes:**
- ✅ **Unit Tests**: Serviços, repositories, jobs
- ✅ **Integration Tests**: APIs, controllers
- ✅ **Mock Objects**: Isolamento de dependências
- ✅ **Edge Cases**: Error handling, timeouts
- ✅ **Performance Tests**: Caching behavior

### 🔧 Executar Testes

```bash
# Todos os testes
cd server
rails test

# Testes específicos
rails test test/services/hacker_news_service_test.rb

# Com cobertura
rails test:coverage
```

## 🔧 Tecnologias Utilizadas

### Backend
- **Ruby on Rails 8.0** - Framework web
- **Action Cable** - WebSocket real-time
- **Puma** - Application server
- **Net::HTTP** - HTTP client nativo
- **Rails Cache** - Sistema de cache
- **dotenv-rails** - Gerenciamento de variáveis de ambiente

### Frontend  
- **Vue.js 3** - Framework reativo
- **Vite** - Build tool e dev server
- **Axios** - HTTP client
- **Action Cable JS** - WebSocket client
- **DOMPurify** - Sanitização XSS


## 📝 API Endpoints

```
GET /api/stories          # Lista top stories
GET /api/stories/search   # Busca stories por query
POST /api/stories/update  # Force cache update
WS /cable                 # WebSocket connection
```


**Desenvolvido com 🎵 usando Ruby on Rails e Vue.js**
