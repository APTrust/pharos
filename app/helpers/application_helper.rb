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
    elsif object.is_a?(WorkItem)
      link_to(content.html_safe, edit_work_item_path(object.id), options) if policy(object).edit?
    else
      link_to(content.html_safe, [:edit, object], options) if policy(object).edit?
    end
  end

  def deactivate_link(object, content = nil, options={})
    content ||= '<i class="glyphicon glyphicon-minus-sign"></i> Deactivate'
    options[:class] = 'btn doc-action-btn btn-warning btn-sm' if options[:class].nil?
    options[:method] = :get if options[:method].nil?
    if object.is_a?(Institution)
      options[:data] = { confirm: 'Are you sure you want to deactivate these users?' } if options[:confirm].nil?
      link_to(content.html_safe, deactivate_institution_path(object), options) if policy(object).deactivate?
    else
      options[:data] = { confirm: 'Are you sure you want to deactivate this user?' } if options[:confirm].nil?
      link_to(content.html_safe, [:deactivate, object], options) if policy(object).deactivate?
    end
  end

  def reactivate_link(object, content = nil, options={})
    content ||= '<i class="glyphicon glyphicon-plus-sign"></i> Reactivate'
    options[:class] = 'btn doc-action-btn btn-success btn-sm' if options[:class].nil?
    options[:method] = :get if options[:method].nil?
    if object.is_a?(Institution)
      options[:data] = { confirm: 'Are you sure you want to reactivate these users?' } if options[:confirm].nil?
      link_to(content.html_safe, reactivate_institution_path(object), options) if policy(object).reactivate?
    else
      options[:data] = { confirm: 'Are you sure you want to reactivate this user?' } if options[:confirm].nil?
      link_to(content.html_safe, [:reactivate, object], options) if policy(object).reactivate?
    end
  end

  def enable_otp_link(object, content = nil, options={})
    options[:class] = 'btn doc-action-btn btn-success btn-sm' if options[:class].nil?
    options[:method] = :get if options[:method].nil?
    if object.is_a?(Institution)
      content ||= '<i class="glyphicon glyphicon-thumbs-up"></i> Enable Mandatory Institution-wide 2FA'
      options[:data] = { confirm: 'Are you sure you want to make Two Factor Authentication mandatory across your entire institution? This will eliminate any remaining grace period left for users at your institution and require them to immediately enable Two Factor Authentication.' } if options[:confirm].nil?
      link_to(content.html_safe, enable_otp_institution_path(object), options) if policy(object).enable_otp?
    else
      content ||= '<i class="glyphicon glyphicon-thumbs-up"></i> Enable 2FA'
      options[:data] = { confirm: 'Are you sure you want to enable Two Factor Authentication for this user?' } if options[:confirm].nil?
      link_to(content.html_safe, users_enable_otp_path(object, redirect_loc: 'index'), options) if policy(object).enable_otp?
    end
  end

  def disable_otp_link(object, content = nil, options={})
    options[:class] = 'btn doc-action-btn btn-warning btn-sm' if options[:class].nil?
    options[:method] = :get if options[:method].nil?
    if object.is_a?(Institution)
      content ||= '<i class="glyphicon glyphicon-thumbs-down"></i> Disable Mandatory Institution-wide 2FA'
      options[:data] = { confirm: 'Are you sure you want to disable mandatory Two Factor Authentication for your entire institution?' } if options[:confirm].nil?
      link_to(content.html_safe, disable_otp_institution_path(object), options) if policy(object).disable_otp?
    else
      content ||= '<i class="glyphicon glyphicon-thumbs-down"></i> Disable 2FA'
      options[:data] = { confirm: 'Are you sure you want to disable Two Factor Authentication for this user?' } if options[:confirm].nil?
      link_to(content.html_safe, users_disable_otp_path(object, redirect_loc: 'index'), options) if policy(object).disable_otp?
    end
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
    release_branch = ENV['PHAROS_BRANCH']
    return "| Pharos #{app_version} Release #{release_version}" if Rails.env.production?
    return "| Pharos #{app_version} Release #{release_version} #{release_branch} | Rails #{Rails.version} | Ruby #{RUBY_VERSION}"
  end

  def current_path(param, value)
    old_path = @current
    old_path = url_for(only_path: false, params: (params.permit(Pharos::Application::PARAMS_HASH).except param)) if old_path.include? param
    old_path = url_for(only_path: false, params: (params.permit(Pharos::Application::PARAMS_HASH).except :page)) if old_path.include? 'page'
    value = '' if value.nil?
    if value.kind_of?(Integer)
      encoded_val = value
    elsif value.include?('+')
      pieces = value.split('+')
      encoded_val = "#{pieces[0]}%2B#{pieces[1]}"
    else
      encoded_val = URI.encode_www_form_component(value)
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
        url = url_for(params.permit(Pharos::Application::PARAMS_HASH).except(:page, :sort, :item_action, :institution, :stage,
                                                                             :status, :access, :file_format, :object_association,
                                                                             :file_association, :type, :state, :event_type, :outcome,
                                                                             :queued, :retry, :remote_node))
      when 'intellectual_objects'
        url = url_for(params.permit(Pharos::Application::PARAMS_HASH).except(:page, :sort, :institution, :access, :file_format,
                                                                             :state, :description, :description_like, :identifier,
                                                                             :identifier_like, :bag_group_identifier,
                                                                             :bag_group_identifier_like, :alt_identifier,
                                                                             :alt_identifier_like, :bag_name, :bag_name_like, :etag,
                                                                             :etag_like, :created_before, :created_after, :updated_before,
                                                                             :updated_after))
      when 'generic_files'
        url = url_for(params.permit(Pharos::Application::PARAMS_HASH).except(:page, :sort, :institution, :access, :file_format,
                                                                             :object_association, :state, :identifier, :identifier_like,
                                                                             :uri, :created_before, :created_after, :updated_before,
                                                                             :updated_after))
      when 'premis_events'
        url = url_for(params.permit(Pharos::Application::PARAMS_HASH).except(:page, :sort, :institution, :access, :object_association,
                                                                             :file_association, :state, :event_type, :outcome, :created_at,
                                                                             :created_before, :created_after, :event_identifier,
                                                                             :object_identifier, :object_identifier_like, :file_identifier,
                                                                             :file_identifier_like))
      when 'work_items'
        url = url_for(params.permit(Pharos::Application::PARAMS_HASH).except(:page, :sort, :item_action, :institution, :stage,
                                                                             :status, :access, :object_association, :file_association,
                                                                             :state, :created_before, :created_after, :updated_before,
                                                                             :updated_after, :updated_since, :bag_date, :name, :name_exact,
                                                                             :name_contains, :etag, :etag_contains, :object_identifier,
                                                                             :object_identifier_contains, :file_identifier,
                                                                             :file_identifier_contains, :queued, :node, :pid, :node_not_empty,
                                                                             :node_empty, :retry, :pid_empty, :pid_not_empty))
    end
    url
  end

  def paginate(scope, count, paginator_class: Kaminari::Helpers::Paginator, template: nil, **options)
    options[:total_pages] ||= (count.to_f / @per_page).ceil
    options.reverse_merge! current_page: scope.current_page, per_page: scope.limit_value, remote: false
    paginator = paginator_class.new (template || self), options
    paginator.to_s
  end

  def pretty_date(date)
    unless date.nil? || date == ''
      zoned_date = date.in_time_zone(Time.zone)
      pretty_date = zoned_date.strftime('%Y-%m-%dT%H:%M:%S %Z') #ISO Format
      pretty_date
    end
  end

end
