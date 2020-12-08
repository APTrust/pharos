module WorkItemsHelper

  def requeue_link(object, content = nil, options={})
    content ||= '<i class="glyphicon glyphicon-repeat"></i> Requeue'
    options[:class] = 'btn doc-action-btn btn-normal requeue-link'
    options[:method] = :get if options[:method].nil?
    options[:data] = { confirm: 'Do you really want to requeue this item for deletion?' } if options[:confirm].nil?
    link_to(content.html_safe, [:requeue, object], options) if policy(object).requeue?
  end

  # CLEANUP: We should be using Pharos::Application::PHAROS_STAGES
  def stages_for_select
   ['Requested', 'Receive', 'Fetch', 'Unpack', 'Validate', 'Store', 'Record', 'Cleanup', 'Resolve', 'Package', 'Restoring', 'Available in S3']
  end

  # CLEANUP: We should be using Pharos::Application::PHAROS_STATUSES
  def statuses_for_select
    %w(Pending Started Success Failed Cancelled)
  end

  def boolean_for_select
    %w(true false)
  end

end
