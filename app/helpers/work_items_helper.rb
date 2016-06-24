module WorkItemsHelper
  def current_path(param, value)
    old_path = request.fullpath
    if old_path.include? 'wi_sort'
      new_path = url_for(params.except :wi_sort)
    else
      new_path = old_path
    end
    if new_path.include? '?'
      path = "#{new_path}&#{param}=#{value}"
    else
      path = "#{new_path}?#{param}=#{value}"
    end
    if new_path.include? 'search'
      unless new_path.include? 'qq'
        path = "#{path}&search_field=#{params[:search_field]}&qq=#{params[:qq]}"
      end
    end
    path
  end
end
