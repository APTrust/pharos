module WorkItemsHelper

  def requeue_link(object, content = nil, options={})
    content ||= '<i class="glyphicon glyphicon-repeat"></i> Requeue'
    options[:class] = 'btn doc-action-btn btn-normal requeue-link'
    options[:method] = :get if options[:method].nil?
    options[:data] = { confirm: 'Do you really want to requeue this item for deletion?' } if options[:confirm].nil?
    link_to(content.html_safe, [:requeue, object], options) if policy(object).requeue?
  end

end
