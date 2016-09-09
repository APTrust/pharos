xml.instruct! :xml, version: '1.0'
xml.rss version: '2.0' do
  xml.channel do
    xml.title 'APTrust Bag Monitor Feed'
    xml.description 'This feed will let you monitor the most recently updated work items, allowing you to keep track of the status of associated bags.'
    xml.link work_items_path

    @rss_items.each { |wi|
      xml.item do
        xml.title wi.name
        xml.description "This work item has an associated etag of #{wi.etag} and a current action, stage, and status of: #{wi.action}, #{wi.stage}, #{wi.status}."
        xml.pubDate wi.date.to_s(:rfc822)
        xml.link work_item_path(wi.id)
        xml.guid work_item_path(wi.id)
      end
    }
  end
end