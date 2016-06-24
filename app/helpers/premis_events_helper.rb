module PremisEventsHelper

  def generic_file_link(event)
    id  = event.generic_file_id
    identifier = GenericFile.find(event.generic_file_id).identifier
    link_name = identifier ? identifier : id
    link_to link_name, generic_file_path(identifier)
  end

  def intellectual_object_link(event)
    id  = event.intellectual_object_id
    identifier = IntellectualObject.find(event.intellectual_object_id).identifier
    link_name = identifier ? identifier : id
    link_to link_name, intellectual_object_path(identifier)
  end

  def parent_object_link(event)
    if event.nil?
      'Event'
    elsif !event.generic_file_id.nil?
      generic_file_link(event)
    elsif !event.intellectual_object_id.nil?
      intellectual_object_link(event)
    else
      'Event'
    end
  end

  def display_event_outcome(event)
    event.outcome unless event.nil?
  end

  def event_catalog_title
    if @parent_object && @parent_object.respond_to?(:title)
      "Events for #{@parent_object.title}"
    elsif @institution
      "Events for #{@institution.name}"
    else
      'Events'
    end
  end

end
