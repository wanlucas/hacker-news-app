module InputSanitizer
  extend ActiveSupport::Concern

  private

  def sanitize_input(input)
    return '' if input.blank?

    sanitized = input.gsub(/<[^>]*>/, '')
    
    sanitized = sanitized.gsub(/[<>"'&;]/, '')
 
    sanitized.squeeze(' ').strip
  end

  def valid_integer?(input, max: 100)
    return false if input.blank?
    return false unless input.match?(/\A\d+\z/)
    
    num = input.to_i
    num > 0 && num <= max
  end
end
