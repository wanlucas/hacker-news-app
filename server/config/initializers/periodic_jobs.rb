Rails.application.configure do
  config.after_initialize do
    Thread.new do
      Thread.current.name = "PeriodicStoriesWorker"
      
      Rails.logger.info "🚀 Worker periódico iniciado - Stories a cada 3 minutos"
      
      loop do
        begin  
          Rails.logger.info "⏰ Executando StoriesUpdateJob periódico"
          StoriesUpdateJob.perform_now

        rescue => error
          Rails.logger.error "❌ Erro no worker periódico: #{error.message}"
        end

        sleep 3.minutes
      end
    end
  end
end
