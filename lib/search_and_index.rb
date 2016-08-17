module SearchAndIndex

  def set_filter_values
    @statuses = WorkItem.distinct.pluck(:status)
    @stages = WorkItem.distinct.pluck(:stage)
    @actions = WorkItem.distinct.pluck(:action)
    @institutions = Institution.pluck(:id)
    @accesses = %w(consortia institution restricted)
    @formats = GenericFile.distinct.pluck(:file_format)
    file_associations = GenericFile.distinct.pluck(:intellectual_object_id)
    item_io_associations = WorkItem.distinct.pluck(:intellectual_object_id)
    item_gf_associations = WorkItem.distinct.pluck(:generic_file_id)
    deduped_io_associations = file_associations | item_io_associations
    @associations = item_gf_associations + deduped_io_associations
    @counts = {}
  end

  def filter_by_status
    @results[:items] = @results[:items].with_status(params[:status]) unless @results.nil? || @results[:items].nil?
    @results.delete(:files) unless @results.nil?
    @results.delete(:objects) unless @results.nil?
    @items = @items.with_status(params[:status]) unless @items.nil?
  end

  def filter_by_stage
    @results[:items] = @results[:items].with_stage(params[:stage]) unless @results.nil? || @results[:items].nil?
    @results.delete(:files) unless @results.nil?
    @results.delete(:objects) unless @results.nil?
    @items = @items.with_stage(params[:stage]) unless @items.nil?
  end

  def filter_by_action
    @results[:items] = @results[:items].with_action(params[:item_action]) unless @results.nil? || @results[:items].nil?
    @results.delete(:files) unless @results.nil?
    @results.delete(:objects) unless @results.nil?
    @items = @items.with_action(params[:item_action]) unless @items.nil?
  end

  def filter_by_institution
    @results[:objects] = @results[:objects].with_institution(params[:institution]) unless @results.nil? || @results[:objects].nil?
    @results[:files] = @results[:files].with_institution(params[:institution]) unless @results.nil? || @results[:files].nil?
    @results[:items] = @results[:items].with_institution(params[:institution]) unless @results.nil? || @results[:items].nil?
    @intellectual_objects = @intellectual_objects.with_institution(params[:institution]) unless @intellectual_objects.nil?
    @items = @items.with_institution(params[:institution]) unless @items.nil?
  end

  def filter_by_access
    @results[:objects] = @results[:objects].with_access(params[:access]) unless @results.nil? || @results[:objects].nil?
    @results[:files] = @results[:files].with_access(params[:access]) unless @results.nil? || @results[:files].nil?
    @results[:items] = @results[:items].with_access(params[:access]) unless @results.nil? || @results[:items].nil?
    @intellectual_objects = @intellectual_objects.with_access(params[:access]) unless @intellectual_objects.nil?
    @items = @items.with_access(params[:access]) unless @items.nil?
  end

  def filter_by_format
    @results[:files] = @results[:files].with_file_format(params[:file_format]) unless @results.nil? || @results[:files].nil?
    @results[:objects] = @results[:objects].with_file_format(params[:file_format]) unless @results.nil? || @results[:objects].nil?
    @results.delete(:items) unless @results.nil?
    @intellectual_objects = @intellectual_objects.with_file_format(params[:file_format]) unless @intellectual_objects.nil?
    @generic_files = @generic_files.with_file_format(params[:file_format]) unless @generic_files.nil?
  end

  def filter_by_association
    @results[:items] = @results[:items].where('intellectual_object_id LIKE ? OR generic_file_id LIKE ?',
                                              params[:association], params[:association]) unless @results.nil? || @results[:items].nil?
    @results[:files] = @results[:files].where(intellectual_object_id: params[:association]) unless @results.nil? || @results[:files].nil?
    @results[:objects] = @results[:objects].where(id: params[:association]) unless @results.nil? || @results[:objects].nil?
    @items = @items.where('intellectual_object_id LIKE ? OR generic_file_id LIKE ?',
                           params[:association], params[:association]) unless @items.nil?
  end

  def filter_by_type
    case params[:type]
      when 'intellectual_object'
        @results.delete(:files)
        @results.delete(:items)
      when 'generic_file'
        @results.delete(:objects)
        @results.delete(:items)
      when 'work_item'
        @results.delete(:objects)
        @results.delete(:files)
    end
  end

  def filter_by_state
    params[:state] = 'A' if params[:state].nil?
    unless params[:state] == 'all'
      @results[:objects] = @results[:objects].with_state(params[:state]) unless @results.nil? || @results[:objects].nil?
      @results[:files] = @results[:files].with_state(params[:state]) unless @results.nil? || @results[:files].nil?
      @results[:items] = @results[:items].with_state(params[:state]) unless @results.nil? || @results[:items].nil?
      @intellectual_objects = @intellectual_objects.with_state(params[:state]) unless @intellectual_objects.nil?
      @generic_files = @generic_files.with_state(params[:state]) unless @generic_files.nil?
      @items = @items.with_state(params[:state]) unless @items.nil?
    end
  end

  def sort
    case params[:sort]
      when 'date'
        sort_by_date
      when 'name'
        sort_by_name
      when 'institution'
        sort_by_institution
    end
  end

  def sort_by_date
    @results[:objects] = @results[:objects].order('created_at').reverse_order unless @results.nil? || @results[:objects].nil?
    @results[:files] = @results[:files].order('created_at').reverse_order unless @results.nil? || @results[:files].nil?
    @results[:items] = @results[:items].order('date').reverse_order unless @results.nil? || @results[:items].nil?
    @intellectual_objects = @intellectual_objects.order('created_at').reverse_order unless @intellectual_objects.nil?
    @generic_files = @generic_files.order('created_at').reverse_order unless @generic_files.nil?
    @items = @items.order('date').reverse_order unless @items.nil?

  end

  def sort_by_name
    @results[:objects] = @results[:objects].order('bag_name') unless @results[:objects].nil?
    @results[:files] = @results[:files].order('uri') unless @results[:files].nil?
    @results[:items] = @results[:items].order('name') unless @results[:items].nil?
    @intellectual_objects = @intellectual_objects.order('bag_name').reverse_order unless @intellectual_objects.nil?
    @generic_files = @generic_files.order('uri') unless @generic_files.nil?
    @items = @items.order('name') unless @items.nil?

  end

  def sort_by_institution
    @results[:objects] = @results[:objects].order('institution_id').reverse_order unless @results[:objects].nil?
    @results[:files] = @results[:files].joins(:intellectual_object).order('institution_id').reverse_order unless @results[:files].nil?
    @results[:items] = @results[:items].order('institution_id').reverse_order unless @results[:items].nil?
    @intellectual_objects = @intellectual_objects.order('institution_id').reverse_order unless @intellectual_objects.nil?
    @generic_files = @generic_files.joins(:intellectual_object).order('institution_id').reverse_order unless @generic_files.nil?
    @items = @items.order('institution_id').reverse_order unless @items.nil?

  end

  def set_inst_count(results)
    #Book.select('type, count(*)').where(:type => ["Banking","IT"]).group(:type)
    # inst_list = ''
    # @institutions.each do |inst|
    #   if inst_list == ''
    #     inst_list = "#{inst}"
    #   else
    #     inst_list = "#{inst_list} , #{inst}"
    #   end
    # end
    #@inst_facet = @results[:objects].select('institution_id, count(*)').where(institution_id: [inst_list]).group(:institution_id)
    unless @institutions.nil?
      @institutions.each do |institution|
        @counts[institution].nil? ?
            @counts[institution] = results.where(institution_id: institution).count :
            @counts[institution] = @counts[institution] + results.where(institution_id: institution).count
      end
    end
  end

  def set_access_count(results)
    unless @accesses.nil?
      @accesses.each do |acc|
        @counts[acc].nil? ?
            @counts[acc] = results.with_access(acc).count :
            @counts[acc] = @counts[acc] + results.with_access(acc).count
      end
    end
  end

  def set_format_count(results)
    unless @formats.nil?
      @formats.each do |format|
        @counts[format].nil? ?
            @counts[format] = results.with_file_format(format).count :
            @counts[format] = @counts[format] + results.with_file_format(format).count
      end
    end
  end

  def set_io_assc_count(results)
    unless @associations.nil?
      @associations.each do |assc|
        @counts[assc].nil? ?
            @counts[assc] = results.where(intellectual_object_id: assc).count :
            @counts[assc] = @counts[assc] + results.where(intellectual_object_id: assc).count
      end
    end
  end

  def set_gf_assc_count(results)
    unless @associations.nil?
      @associations.each do |assc|
        @counts[assc].nil? ?
            @counts[assc] = results.where(generic_file_id: assc).count :
            @counts[assc] = @counts[assc] + results.where(generic_file_id: assc).count
      end
    end
  end

  def set_status_count(results)
    unless @statuses.nil?
      @statuses.each do |status|
        @counts[status].nil? ?
            @counts[status] = results.where(status: status).count :
            @counts[status] = @counts[status] + results.where(status: status).count
      end
    end
  end

  def set_stage_count(results)
    unless @stages.nil?
      @stages.each do |stage|
        @counts[stage].nil? ?
            @counts[stage] = results.where(stage: stage).count :
            @counts[stage] = @counts[stage] + results.where(stage: stage).count
      end
    end
  end

  def set_action_count(results)
    unless @actions.nil?
      @actions.each do |action|
        @counts[action].nil? ?
            @counts[action] = results.where(action: action).count :
            @counts[action] = @counts[action] + results.where(action: action).count
      end
    end
  end

  def set_page_counts(count)
    @count = count
    if @count == 0
      @second_number = 0
      @first_number = 0
    elsif params[:page].nil?
      @second_number = 10
      @first_number = 1
    else
      @second_number = params[:page].to_i * params[:per_page].to_i
      @first_number = (@second_number.to_i - params[:per_page].to_i) + 1
    end
    @second_number = @count if @second_number > @count
  end

  def page_results(results)
    params[:page] = 1 unless params[:page].present?
    params[:per_page] = 10 unless params[:per_page].present?
    @page = params[:page].to_i
    @per_page = params[:per_page].to_i
    @paged_results = Kaminari.paginate_array(results).page(@page).per(@per_page)
    @next = format_next
    @current = format_current
    @previous = format_previous
  end

  def format_date
    time = Time.parse(params[:updated_since])
    time.utc.iso8601
  end

  def to_boolean(str)
    str == 'true'
  end

  def format_current
    path = request.fullpath.split('?').first
    new_url = "#{request.base_url}#{path}?page=#{@page}&per_page=#{@per_page}"
    new_url = add_params(new_url)
    new_url
  end

  def format_next
    if @count.to_f / @per_page <= @page
      nil
    else
      path = request.fullpath.split('?').first
      new_page = @page + 1
      new_url = "#{request.base_url}#{path}/?page=#{new_page}&per_page=#{@per_page}"
      new_url = add_params(new_url)
      new_url
    end
  end

  def format_previous
    if @page == 1
      nil
    else
      path = request.fullpath.split('?').first
      new_page = @page - 1
      new_url = "#{request.base_url}#{path}/?page=#{new_page}&per_page=#{@per_page}"
      new_url = add_params(new_url)
      new_url
    end
  end

  def add_params(str)
    str = str << "&q=#{URI.escape(params[:q])}" if params[:q].present?
    str = str << "&search_field=#{URI.escape(params[:search_field])}" if params[:search_field].present?
    str = str << "&object_type=#{URI.escape(params[:object_type])}" if params[:object_type].present?
    str = str << "&institution=#{params[:institution]}" if params[:institution].present?
    str = str << "&item_action=#{params[:item_action]}" if params[:item_action].present?
    str = str << "&stage=#{params[:stage]}" if params[:stage].present?
    str = str << "&status=#{params[:status]}" if params[:status].present?
    str = str << "&access=#{params[:access]}" if params[:access].present?
    str = str << "&format=#{params[:file_format]}" if params[:file_format].present?
    str = str << "&association=#{params[:association]}" if params[:association].present?
    str = str << "&type=#{params[:type]}" if params[:type].present?
    str = str << "&sort=#{params[:sort]}" if params[:sort].present?
    str = str << "&state=#{params[:state]}" if params[:state].present?
    str = str << "&institution_identifier=#{params[:institution_identifier]}" if params[:institution_identifier].present?
    str = str << "&name_contains=#{params[:name_contains]}" if params[:name_contains].present?
    str = str << "&name_exact=#{params[:name_exact]}" if params[:name_exact].present?
    str = str << "&updated_since=#{params[:updated_since]}" if params[:updated_since].present?
    str = str << "&reviewed=#{params[:reviewed]}" if params[:reviewed].present?
    str = str << "&node=#{params[:node]}" if params[:node].present?
    str = str << "&reviewed=#{params[:needs_admin_review]}" if params[:needs_admin_review].present?
    str
  end
end