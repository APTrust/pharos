module ApplicationHelper
  def show_link(object, content = nil, options={})
    content ||= '<i class="glyphicon glyphicon-eye-open"></i> View'
    options[:class] = 'btn doc-action-btn btn-normal btn-sm' if options[:class].nil?
    link_to(content.html_safe, object, options) if policy(object).show?
  end

  def edit_link(object, content = nil, options={})
    content ||= '<i class="glyphicon glyphicon-edit"></i> Edit'
    options[:class] = 'btn doc-action-btn btn-normal btn-sm' if options[:class].nil?
    link_to(content.html_safe, [:edit, object], options) if policy(object).edit?
  end

  def destroy_link(object, content = nil, options={})
    content ||= '<i class="glyphicon glyphicon-trash"></i> Delete'
    options[:class] = 'btn doc-action-btn btn-danger btn-sm' if options[:class].nil?
    options[:method] = :delete if options[:method].nil?
    options[:data] = { confirm: 'Are you sure?' } if options[:confirm].nil?
    link_to(content.html_safe, object, options) if policy(object).destroy?
  end

  def admin_password_link(object, content = nil, options={})
    content ||= '<i class="glyphicon glyphicon-warning-sign"></i> Reset User Password'
    options[:class] = 'btn doc-action-btn btn-danger btn-sm' if options[:class].nil?
    options[:method] = :get if options[:method].nil?
    options[:data] = { confirm: 'Are you sure?' }if options[:confirm].nil?
    link_to(content.html_safe, [:admin_password_reset, object], options) if policy(object).admin_password_reset?
  end

  def create_link(object, content = nil, options={})
    content ||= '<i class="glyphicon glyphicon-plus"></i> Create'
    options[:class] = 'btn doc-action-btn btn-success btn-sm' if options[:class].nil?
    if policy(object).create?
      object_class = (object.kind_of?(Class) ? object : object.class)
      link_to(content.html_safe, [:new, object_class.name.underscore.to_sym], options)
    end
  end

  def format_boolean_as_yes_no(boolean)
    if boolean == 'true'
      return 'Yes'
    else
      return 'No'
    end
  end

  def display_version
    app_version = Pharos::Application::VERSION
    release_version = ENV['PHAROS_RELEASE']
    return "Pharos #{app_version} | Release #{release_version}" if Rails.env.production?
    return "Pharos #{app_version} | Release #{release_version} | Rails #{Rails.version} | Ruby #{RUBY_VERSION}"
  end

  def current_path(param, value)
    old_path = @current
    old_path = url_for(params.except param) if old_path.include? param
    old_path = url_for(params.except :page) if old_path.include? 'page'
    if value.kind_of?(Fixnum)
      encoded_val = value
    elsif value.include?('+')
      pieces = value.split('+')
      encoded_val = "#{pieces[0]}%2B#{pieces[1]}"
    else
      encoded_val = URI.escape(value)
    end
    if old_path.include? '?'
      new_path = "#{old_path}&#{param}=#{encoded_val}"
    else
      new_path = "#{old_path}?#{param}=#{encoded_val}"
    end
    new_path
  end

  def start_over_link(controller)
    case controller
      when 'catalog'
        url = url_for(params.except(:page, :sort, :item_action, :institution, :stage, :status, :access, :file_format, :object_association,
                                    :file_association, :type, :state, :event_type, :outcome))
      when 'intellectual_objects'
        url = url_for(params.except(:page, :sort, :institution, :access, :file_format, :state))
      when 'generic_files'
        url = url_for(params.except(:page, :sort, :institution, :access, :file_format, :object_association, :state))
      when 'premis_events'
        url = url_for(params.except(:page, :sort, :institution, :access, :object_association, :file_association, :state, :event_type, :outcome))
      when 'work_items'
        url = url_for(params.except(:page, :sort, :item_action, :institution, :stage, :status, :access, :object_association, :file_association, :state))
    end
    url
  end
end
