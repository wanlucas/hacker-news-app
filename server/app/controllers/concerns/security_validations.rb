module InputSanitizer
  extend ActiveSupport::Concern

  private

  def sanitize_input(input)
    return '' if input.blank?

    sanitized = input.gsub(/<[^>]*>/, '')
    
    sanitized = sanitized.gsub(/[<>"'&;]/, '')
 
    sanitized.squeeze(' ').strip
  end
end
