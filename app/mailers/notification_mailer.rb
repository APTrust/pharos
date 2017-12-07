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
    email_log.email_text = "Admin Users at #{@event_institution.name}, This email notification is to inform you that one of your files failed a fixity check. The failed fixity check can be found at the following link: #{premis_event_url(id: @event.id)}. Please contact the APTrust team by replying to this email if you have any questions."
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
    email_log.email_text = "Admin Users at #{@item_institution.name}, This email notification is to inform you that one of your restoration requests has successfully completed. The finished record of the restoration can be found at the following link: #{work_item_url(id: @item.id)}. Please contact the APTrust team by replying to this email if you have any questions."
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
    email_log.email_text = "Admin Users at #{@event_institution.name}, This email notification is to inform you that one ore more of your files failed a fixity check. The failed fixity checks can be found at the following link: #{@events_url} A comprehensive list of failed fixity checks can be found below. Please contact the APTrust team by replying to this email if you have any questions."
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
    email_log.email_text = "Admin Users at #{@item_institution.name}, This email notification is to inform you that one or more of your restoration requests has successfully completed. The finished restorations can be found at the following link: #{@items_url} A comprehensive list of completed restorations can be found below. Please contact the APTrust team by replying to this email if you have any questions."
    email_log.save!
    mail(to: emails, subject: 'Restoration notification on one or more of your bags')
  end

  def deletion_request(subject, requesting_user, email_log, confirmation_token)
    @subject = subject
    @subject_institution = subject.institution
    @requesting_user = requesting_user
    if @subject.is_a?(IntellectualObject)
      @subject_url = intellectual_object_url(@subject)
      @confirmation_url = object_confirm_destroy_url(@subject, requesting_user_id: @requesting_user.id, confirmation_token: confirmation_token.token)
      subject_line = @subject.title
    elsif @subject.is_a?(GenericFile)
      @subject_url = generic_file_url(@subject)
      @confirmation_url = file_confirm_destroy_url(@subject, requesting_user_id: @requesting_user.id, confirmation_token: confirmation_token.token)
      subject_line = @subject.identifier
    end
    users = @subject_institution.deletion_admin_user(requesting_user)
    users.push(@requesting_user) if users.count == 0
    emails = []
    users.each { |user| emails.push(user.email) }
    email_log.user_list = emails.join('; ')
    email_log.email_text = "Admin Users at #{@subject_institution.name}, This email notification is to inform you that <%= @requesting_user.name %> has requested the deletion of the following item: #{@subject_url} To confirm that this object should be deleting please click the following link: #{@confirmation_url} Please contact the APTrust team by replying to this email if you have any questions."
    email_log.save!
    mail(to: emails, subject: "#{requesting_user.name} has requested deletion of #{subject_line}")
  end

  def deletion_confirmation(subject, requesting_user, email_log)
    @subject = subject
    @subject_institution = subject.institution
    @requesting_user = requesting_user
    if @subject.is_a?(IntellectualObject)
      @subject_url = intellectual_object_url(@subject)
      subject_line = @subject.title
    elsif @subject.is_a?(GenericFile)
      @subject_url = generic_file_url(@subject)
      subject_line = @subject.identifier
    end
    users = @subject_institution.deletion_admin_user(requesting_user)
    users.push(requesting_user) unless users.include?(requesting_user)
    emails = []
    users.each { |user| emails.push(user.email) }
    email_log.user_list = emails.join('; ')
    email_log.email_text = "Admin Users at #{@subject_institution.name}, This email notification is to inform you that the following item, whose deletion was requested by <%= @requesting_user.name %>, has been successfully queued for deletion: #{@subject_url} Depending on the size of the object, it may take a few minutes for all associated files to be marked as deleted - if only a single file has been marked for deletion, this will not be an issue. Please contact the APTrust team by replying to this email if you have any questions."
    email_log.save!
    mail(to: emails, subject: "#{subject_line} queued for deletion")
  end

end
