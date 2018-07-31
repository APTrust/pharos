module ApplicationHelper
  def show_link(object, content = nil, options={})
    content ||= '<i class="glyphicon glyphicon-eye-open"></i> View'
    options[:class] = 'btn doc-action-btn btn-normal btn-sm' if options[:class].nil?
    link_to(content.html_safe, object, options) if policy(object).show?
  end

  def edit_link(object, content = nil, options={})
    content ||= '<i class="glyphicon glyphicon-edit"></i> Edit'
    options[:class] = 'btn doc-action-btn btn-normal btn-sm' if options[:class].nil?
    if object.is_a?(Institution)
      link_to(content.html_safe, edit_institution_path(object), options) if policy(object).edit?
    else
      link_to(content.html_safe, [:edit, object], options) if policy(object).edit?
    end
  end

  def deactivate_link(object, content = nil, options={})
    content ||= '<i class="glyphicon glyphicon-lock"></i> Deactivate'
    options[:class] = 'btn doc-action-btn btn-warning btn-sm' if options[:class].nil?
    options[:method] = :get if options[:method].nil?
    options[:data] = { confirm: 'Are you sure you want to deactivate this user?' } if options[:confirm].nil?
    # if object.is_a?(Institution)
    #   link_to(content.html_safe, institution_path(object), options) if policy(object).destroy?
    # else
      link_to(content.html_safe, [:deactivate, object], options) if policy(object).deactivate?
    # end
  end

  def destroy_link(object, content = nil, options={})
    content ||= '<i class="glyphicon glyphicon-trash"></i> Delete'
    options[:class] = 'btn doc-action-btn btn-danger btn-sm' if options[:class].nil?
    options[:method] = :delete if options[:method].nil?
    options[:data] = { confirm: 'Are you sure you want to delete this?' } if options[:confirm].nil?
    if object.is_a?(Institution)
      link_to(content.html_safe, institution_path(object), options) if policy(object).destroy?
    else
      link_to(content.html_safe, object, options) if policy(object).destroy?
    end
  end

  def admin_password_link(object, content = nil, options={})
    content ||= '<i class="glyphicon glyphicon-warning-sign"></i> Reset User Password'
    options[:class] = 'btn doc-action-btn btn-danger btn-sm' if options[:class].nil?
    options[:method] = :get if options[:method].nil?
    options[:data] = { confirm: "Are you sure you want to reset this user's password?" }if options[:confirm].nil?
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

  def format_display(format)
    format == 'all' ? 'Total Content Upload' : format
  end

  def format_class(format)
    format.split('/')[-1].downcase.gsub(/\s/, '_') + '_label' unless format.split('/')[-1].nil?
  end

  def get_institution_for_tabs
    if @institution && !@institution.id.nil?
      @inst = @institution
    else
      @inst = current_user.institution
    end

  end

  def dpn_process_time(item)
    if item.completed_at && item.queued_at
      process_time = ((item.completed_at.to_f - item.queued_at.to_f) / 1.hour).round(2)
      if process_time == 1
        process_final = '1 hour'
      else
        process_final = "#{process_time} hours"
      end
    elsif item.completed_at.nil? && item.queued_at.nil?
      process_final = 'N/A'
    elsif item.completed_at.nil?
      process_final = 'In Progress'
    elsif item.queued_at.nil?
      process_final = 'Item is Magic'
    end
    process_final
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
    return "| Pharos #{app_version} Release #{release_version}" if Rails.env.production?
    return "| Pharos #{app_version} Release #{release_version} | Rails #{Rails.version} | Ruby #{RUBY_VERSION}"
  end

  def current_path(param, value)
    old_path = @current
    old_path = url_for(params.permit(Pharos::Application::PARAMS_HASH).except param) if old_path.include? param
    old_path = url_for(params.permit(Pharos::Application::PARAMS_HASH).except :page) if old_path.include? 'page'
    if value.kind_of?(Integer)
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
    # params[param] = encoded_val
    # new_path = url_for(params.permit(Pharos::Application::PARAMS_HASH))
    new_path
  end

  def start_over_link(controller)
    case controller
      when 'catalog'
        url = url_for(params.permit(Pharos::Application::PARAMS_HASH).except(:page, :sort, :item_action, :institution, :stage, :status, :access, :file_format, :object_association,
                                    :file_association, :type, :state, :event_type, :outcome))
      when 'intellectual_objects'
        url = url_for(params.permit(Pharos::Application::PARAMS_HASH).except(:page, :sort, :institution, :access, :file_format, :state))
      when 'generic_files'
        url = url_for(params.permit(Pharos::Application::PARAMS_HASH).except(:page, :sort, :institution, :access, :file_format, :object_association, :state))
      when 'premis_events'
        url = url_for(params.permit(Pharos::Application::PARAMS_HASH).except(:page, :sort, :institution, :access, :object_association, :file_association, :state, :event_type, :outcome))
      when 'work_items'
        url = url_for(params.permit(Pharos::Application::PARAMS_HASH).except(:page, :sort, :item_action, :institution, :stage, :status, :access, :object_association, :file_association, :state))
    end
    url
  end

  def paginate(scope, count, paginator_class: Kaminari::Helpers::Paginator, template: nil, **options)
    options[:total_pages] ||= (count.to_f / @per_page).ceil
    options.reverse_merge! current_page: scope.current_page, per_page: scope.limit_value, remote: false
    paginator = paginator_class.new (template || self), options
    paginator.to_s
  end

end
