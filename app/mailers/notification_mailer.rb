class NotificationMailer < ApplicationMailer
  default from: 'info@aptrust.org'

  def failed_fixity_notification(event, email_log)
    @event_institution = event.institution
    @event = event
    @event_url = premis_event_url(id: @event.id)
    users = @event_institution.admin_users
    emails = []
    users.each { |user| emails.push(user.email) }
    emails.push('help@aptrust.org')
    email_log.user_list = emails.join('; ')
    email_log.email_text = 'Admin Users at #{@event_institution.name}, This email notification is to inform you that one of your files failed a fixity check. The failed fixity check can be found at the following link: <a href="<%= premis_event_url(id: @event.id) %>" ><%= @event.identifier %></a>. Please contact the APTrust team by replying to this email if you have any questions.'
    email_log.save!
    mail(to: emails, subject: 'Failed fixity check on one of your files')
  end

  def restoration_notification(work_item, email_log)
    @item_institution = work_item.institution
    @item = work_item
    @item_url = work_item_url(id: @item.id)
    users = @item_institution.admin_users
    emails = []
    users.each { |user| emails.push(user.email) }
    emails.push('help@aptrust.org')
    email_log.user_list = emails.join('; ')
    email_log.email_text = 'Admin Users at #{@item_institution.name}, This email notification is to inform you that one of your restoration requests has successfully completed. The finished record of the restoration can be found at the following link: <a href="<%= work_item_url(id: @item.id) %>" ><%= @item.object_identifier %></a>. Please contact the APTrust team by replying to this email if you have any questions.'
    email_log.save!
    mail(to: emails, subject: 'Restoration complete on one of your work items')
  end

  def multiple_failed_fixity_notification(events, email_log, event_institution)
    @event_institution = event_institution
    @events = events
    @events_url = institution_events_url(@event_institution, event_type: 'Fixity Check', outcome: 'Failure')
    users = @event_institution.admin_users
    emails = []
    users.each { |user| emails.push(user.email) }
    emails.push('help@aptrust.org')
    email_log.user_list = emails.join('; ')
    email_log.save!
    mail(to: emails, subject: 'Failed fixity check on one or more of your files')
  end

  def multiple_restoration_notification(work_items, email_log, item_institution)
    @item_institution = item_institution
    @items = work_items
    @items_url = work_items_url(institution: @item_institution.id,
                                stage: Pharos::Application::PHAROS_STAGES['record'],
                                item_action: Pharos::Application::PHAROS_ACTIONS['restore'],
                                status: Pharos::Application::PHAROS_STATUSES['success'])
    users = @item_institution.admin_users
    emails = []
    users.each { |user| emails.push(user.email) }
    emails.push('help@aptrust.org')
    email_log.user_list = emails.join('; ')
    email_log.save!
    mail(to: emails, subject: 'Restoration notification on one or more of your bags')
  end

  def multi_factor_delete(intellectual_object, requesting_user)
    @object_institution = intellectual_object.institution
    @object = intellectual_object
    @confirmation_url
    users = @object_institution.deletion_admin_user(requesting_user)
    emails = []
    users.each { |user| emails.push(user.email) }
    email_log.user_list = emails.join('; ')
    email_log.save!
    mail(to: emails, subject: "#{requesting_user.name} has requested deletion of #{@object.name}")
  end

end
