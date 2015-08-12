require_relative '../connections/url.rb'

class ConceptcarzStructure
  def self.get_models(manufacturers)
    manufacturers = manufacturers.map do |manufacturer|
      next if manufacturer[:name] == nil || manufacturer[:name] == '' || manufacturer[:name] == ' ' || manufacturer[:name].nil?

      # get page
      doc            = Network.get_parsed_source(Url.root_conceptcarz + manufacturer[:url])
      model_elements = doc.css('div.center-content a')
      model_links    = model_elements.map { |a| a.attr('href') }
      model_links    = clear_model_links(model_links)

      manufacturer[:models] = model_links.map { |url| {
          title: capitalize_model_title(extract_model_from_url(url, manufacturer)),
          name:  extract_model_from_url(url, manufacturer),
          url:   url } if correct_url(extract_model_from_url(url, manufacturer))
      }

      manufacturer[:models] -= [nil, '']
      manufacturer[:models] = get_model_body_types(manufacturer[:models], manufacturer[:url], manufacturer[:title])
      manufacturer
    end
    manufacturers
  end

  def self.get_model_body_types(models, url, manufacturer_title)
    models = models.map do |model|
      next if model == nil || model == '' || model == ' ' || model.nil?

      begin
        # get page
        doc = Network.get_parsed_source(model[:url])
      rescue SocketError
        next
      rescue Mechanize::ResponseCodeError
        next
      end

      model_elements = doc.css('div#ddcolortabs ul li a')

      year_links = model_elements.map { |a| a.attr('href') }

      img_link = nil
      url_link = nil
      year_links.each do |link|
        origin = link
        # gallery link
        if origin =~ /&i=4/
          url_link = origin
          # wallpaper link
        elsif origin =~ /&i=3/
          url_link = origin
          # specification link
        elsif origin =~ /&i=2/
          img_link = origin
          # last hope, if gallery and wallpaper link is empty.
        else
          url_link = model[:url]
        end
      end

      # Uniq!
      # url => Specification Url
      model[:body_types] = year_links.map { |el| { name: '-', image_url: url_link, url: img_link } }.uniq
      model[:body_types] = get_model_years(model[:body_types], model[:url], manufacturer_title)
      model
    end
    models
  end

  # get car years
  def self.get_model_years(body_types, url, manufacturer_title)
    years = body_types.each do |body_type|
      next if body_type == nil || body_type == '' || body_type == ' ' || body_type.nil?

      begin
        # get page
        doc = Network.get_parsed_source(body_type[:image_url])
      rescue SocketError
        next
      rescue Mechanize::ResponseCodeError
        next
      end

      #todo Image logic!!!
      # if 1 == 1
      #   image_elements = doc.css('div#wallpaperPhotos ul li')
      #   highest_res_link = {}
      #
      #   image_elements.each do |li|
      #     width = li.css('a').last.text.slice(0, li.css('a').last.text.index('x')).to_i
      #     height = li.css('a').last.text.slice(li.css('a').last.text.index('x')+1, li.css('a').last.text.length).to_i
      #
      #     # if width == 1920
      #     #   puts "1920"
      #     #   xxx = li.css('a').first
      #     #   xxx.css()
      #     # elsif width == 1600
      #     #   puts "wht"
      #     #   #puts li.css('a').first
      #     # end
      #
      #     if highest_res_link == {}
      #       highest_res_link = {a: li.css('a').first, width: width, height: height}
      #       puts highest_res_link
      #       #next
      #     end
      #     #
      #     # if highest_res_link[:width] > width
      #     #   highest_res_link = {a: li.css('a').first, width: width, height: height}
      #     # end
      #   end
      #
      # else
      #   # for gallery and information page
      #   image_elements = doc.css('td div.thumbnails a img')
      # end

      #images = image_elements.map { |a| a.attr('src') }
      #clean_images = clear_thumbnails(images)

      # get generation year

      begin
        # get page
        doc = Network.get_parsed_source(body_type[:url])
      rescue SocketError
        next
      rescue Mechanize::ResponseCodeError
        next
      end

      model_elements = doc.css('tr.ratingStyle td.ratingStyle a')
      years          = model_elements.map { |a| { year: a.text } }
      cleared_years  = clean_years(years)
      result_years   = cleared_years.map { |year| { year: year } }

      # if genration year is null, switch back to car model year
      if cleared_years.empty?
        doc           = Network.get_parsed_source(body_type[:url])
        year_elements = doc.css('div p b')
        result_years  = year_elements.map { |year| { year: merge_years(year) } }
      end

      body_type[:years] = result_years
      body_type[:years] = get_versions(body_type[:years], url, body_type[:url], manufacturer_title)
      # , clean_images)
      body_type
    end
    years
  end

  # get versions
  def self.get_versions(years, url, spec_url, manufacturer_title)
    # , clean_images)
    versions = years.map do |year|
      next if year == nil || year == '' || year == ' ' || year.nil?

      doc            = Network.get_parsed_source(url)
      model_elements = doc.css('table.floatLeft tbody tr')
      engines        = model_elements.map { |a| { model_type: a.text.gsub(/Power.*/, '').strip } }

      cleared_trims   = get_engine_type(engines)

      # if cleared_trims.empty?
      #   result_trims = clean_images.map { |image| {model_type: '-', image_link: image} }
      # else
      result_trims    = cleared_trims.map { |trim| { model_type: trim } }
      # , image_link: clean_images} }
      # end

      year[:versions] = result_trims
      year[:versions] = get_car_info(year[:versions], spec_url, manufacturer_title)
      year
    end
    versions
  end

  def self.get_car_info(versions, spec_url, manufacturer_title)
    versions = versions.map do |version|
      next if version == nil || version == '' || version == ' ' || version.nil?

      doc = Network.get_parsed_source(spec_url)


      info_elements = doc.css('div.vehicleSpecs tr.ratingStyle')

      result_set = []
      info_elements.each do |element|
        meaning          = element.css('td').first.text.strip
        filtered_meaning = clean_meaning(meaning, manufacturer_title)

        value          = element.css('td').last.text.strip
        filtered_value = clean_value(value, manufacturer_title)

        if filtered_meaning.nil? || filtered_value.nil?
          next
        else
          meaning = filtered_meaning
          value   = filtered_value
        end
        result_set << { name: meaning, value: value }
      end

      version[:details] = result_set
      version
    end
    versions
  end

  private

  def self.clear_model_links(model_links)
    valid_links = []
    model_links.each do |link|
      case
        when link =~ /byYear/
          next
        when link =~ /MakeID/
          next
        when link =~ /makeID/
          next
        when link =~ /make\.aspx/
          next
        when link =~ /showThumbs/
          next
        else
          valid_links << link
      end
    end
    valid_links.uniq
  end

  def self.extract_model_from_url(url, manufacturer)
    manufacturer_title = manufacturer[:title]
    url                = url.slice(0, (url.size-1)) # cut off last '/'
    rindex             = url.rindex('/') # find now the last '/'

    if rindex != nil
      url = url.slice(rindex+1, url.size) # cut form last '/' till end
    end

    url   = url.gsub(/#{manufacturer_title}-/, '').strip
    url   = url.gsub(/.asp/, '').downcase.strip
    url   = url.gsub(/---/, '-').strip
    url   = url.gsub(/--/, '-').strip
    index = url.index('-') # find now the last '/'

    if index != nil
      url = url.slice(index+1, url.size) # cut form first '-' till end
    end
    url
  end

  def self.correct_url(url)
    %w(www. history).each do |element|
      return false if url.include?(element)
    end
    true
  end

  def self.clean_years(years)
    valid_years = []

    years.each do |element|
      if element[:year] =~ /^\d{1,4}[\s]-[\s]/
        if element[:year] =~ /^\d{1,4}[\s]-[\s]\d{1,4}/
          year = element[:year]
          valid_years << year
        else
          year_present = element[:year] + 'Present'
          valid_years << year_present
        end
      end
    end
    valid_years
  end

  def self.get_engine_type(engines)
    valid_trims = []

    engines.each do |engine|
      if engine[:model_type] =~ /^Engine/
        valid_trims << engine[:model_type].gsub(/Engine :/, '').strip
      end
    end
    valid_trims
  end

  def self.clear_thumbnails(images)
    valid_images = []

    images.each do |image|
      if image.nil?
        next
      else
        valid_images << image.gsub(/t_/, '')
      end
    end
    valid_images
  end

  def self.merge_years(year)
    year = year.text.slice(0, 4).strip
    year = year + ' - ' + year
    year
  end

  def self.capitalize_model_title(model_title)
    model_title = model_title.gsub(/-/, ' ')
    model_title = model_title.split.map(&:capitalize)*' '
    model_title
  end

  def self.clean_meaning(meaning, manufacturer_title)
    # need to refactor to any? method # so bad
    if meaning.empty? || meaning.parameterize == '' || meaning =~ /Production/ || meaning =~ /Tires/ ||
        meaning =~ /Suspension/ || meaning =~ /Wheels/ || meaning =~ /Price/ || meaning =~ /#{manufacturer_title}/
      return
    else
      meaning
    end
  end

  def self.clean_value(value, manufacturer_title)
    if value.empty? || value =~ /#{manufacturer_title}/
      return
    else
      value
    end
  end
end
