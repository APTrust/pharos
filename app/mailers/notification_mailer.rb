class NotificationMailer < ApplicationMailer
  default from: 'info@aptrust.org'

  def failed_fixity_notification(event, email_log)
    @event_institution = event.institution
    @event = event
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
    users = @item_institution.admin_users
    emails = []
    users.each { |user| emails.push(user.email) }
    emails.push('help@aptrust.org')
    email_log.user_list = emails.join('; ')
    email_log.email_text = 'Admin Users at #{@item_institution.name}, This email notification is to inform you that one of your restoration requests has successfully completed. The finished record of the restoration can be found at the following link: <a href="<%= work_item_url(id: @item.id) %>" ><%= @item.object_identifier %></a>. Please contact the APTrust team by replying to this email if you have any questions.'
    email_log.save!
    mail(to: emails, subject: 'Restoration complete on one of your work items')
  end

end
