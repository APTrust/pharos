module RedisHelper

  def get_obj_record(work_item)
    return nil unless !Redis.current.connected?
    field = "object:#{work_item.construct_obj_identifier}"
    Redis.current.hget(work_item.id, field)
  end

  def get_work_results(work_item)
    return nil unless !Redis.current.connected?
    results = []
    ingest_topic_names.each do |topic|
      field = "workresult:#{topic}"
      results.push(Redis.current.hget(work_item.id, field))
    end
    results
  end

  def ingest_topic_names
    topic_map = NSQ_TOPIC_FOR_STAGE::Application::NSQ_TOPIC_FOR_STAGE
    topic_map.values.compact.select{ |t| t.start_with?('ingest') }
  end
end
