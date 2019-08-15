module InstitutionsHelper

  def member_institutions_for_select
    MemberInstitution.all.order('name').select {|institution| policy(institution).new? }
  end

  def types_for_select
    %w(MemberInstitution SubscriptionInstitution)
  end

  def mass_pass_update_link(inst, content = nil, options={})
    content ||= '<i class="glyphicon glyphicon-exclamation-sign"></i> Institution Wide Force Password Update'
    options[:class] = 'btn btn-warning doc-action-btn btn-sm' if options[:class].nil?
    options[:data] = { confirm: 'Are you sure you want to force all the users at your institution to update their password?' } if options[:confirm].nil?
    link_to(content.html_safe, mass_forced_password_update_path(inst), options) if policy(inst).mass_forced_password_update?
  end

end
