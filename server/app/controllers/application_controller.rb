class ApplicationController < ActionController::API
  rescue_from StandardError, with: :handle_error

  private

  def handle_error(exception)
    Rails.logger.error "Erro: #{exception.message}"
    
    render json: {
      success: false,
      message: "Internal server error",
    }, status: 500
  end
end
