module ReportsHelper

  def cost_analysis_member(size)
    price = ''
    if size < 10995116277760 #10 TB
      price = 0.00
    else
      excess = size - 10995116277760
      price = cost_analysis_subscriber(excess)
    end
    price
  end

  def cost_analysis_subscriber(size)
    cost = size * 0.000000000381988
    price = cost.round(2)
    price
  end

  def mimetype_analysis
    @application_report = {}
    @audio_report = {}
    @image_report = {}
    @video_report = {}
    @text_report = {}
    @other_report = {}
    application_total = 0
    audio_total = 0
    image_total = 0
    video_total = 0
    text_total = 0
    other_total = 0
    @base_report = {}
    @mimetype_report = Hash[@mimetype_report.sort]
    @mimetype_report.each do |mimetype, count|
      base_type = mimetype.split('/')[0]
      case base_type
        when 'application'
          @application_report[mimetype] = count
          application_total += count
        when 'audio'
          @audio_report[mimetype] = count
          audio_total += count
        when 'video'
          @video_report[mimetype] = count
          video_total += count
        when 'image'
          @image_report[mimetype] = count
          image_total += count
        when 'text'
          @text_report[mimetype] = count
          text_total += count
        else
          unless base_type == 'all'
            @other_report[mimetype] = count
            other_total += count
          end
      end
    end
    @base_report['Applications'] = application_total
    @base_report['Audio'] = audio_total
    @base_report['Video'] = video_total
    @base_report['Image'] = image_total
    @base_report['Text'] = text_total
    @base_report['Other'] = other_total
    @base_report = Hash[@base_report].sort
  end

  def readable_bytes(data_point)
    gb = data_point / 1073741824
    gb = gb.round(2)
    gb
  end

end
