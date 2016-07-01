module DeviseHelper
  def devise_error_messages!
    return '' if @user.errors.empty?

    messages = @user.errors.full_messages.map { |msg| content_tag(:li, msg) }.join
    if (messages.include? 'Email not found') || (messages.include? 'Reset')
      message = messages
    elsif messages.include? ' be blank'
      if current_user.nil?
        message = messages
      end
    end

    html = <<-HTML
    <br/>
    <div id="error_explanation">
      <div class="alert alert-error">Please review the problems below:</div>
      <div class="controls help-inline">
           <ul>
             #{message}
           </ul>
      </div>
    </div>
    HTML

    html.html_safe
  end

  def devise_error_messages?
    @user.errors.empty? ? false : true
  end

end