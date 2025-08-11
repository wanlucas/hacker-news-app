module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :user_id

    def connect
      self.user_id = "user_#{SecureRandom.hex(4)}"
      Rails.logger.info "🔌 Nova conexão WebSocket estabelecida: #{user_id}"
    end
  end
end