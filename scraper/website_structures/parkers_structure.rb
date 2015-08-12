#!/usr/bin/env ruby
# encoding: utf-8
class ParkersStructure
  def self.get_models(manufacturers)
    manufacturers = manufacturers.each do |manufacturer|
      #TODO REMOVE AFTER IMAGE LOGIC
      #next unless manufacturer[:name] == 'alfa-romeo'
      puts manufacturer
      sleep 1

      next if manufacturer[:name] == nil || manufacturer[:name] == '' || manufacturer[:name] == ' ' || manufacturer[:name].nil?

      begin
        # get page
        doc = Network.get_parsed_source(Url.parkers_reviews + manufacturer[:name])
      rescue SocketError
        next
      rescue Mechanize::ResponseCodeError
        next
      end

      model_elements = doc.css('div.greySelectorBar.topRanges.ranges ul li a')

      models = model_elements.map do |el|
        urls = extract_model_url(el)
        if urls
          { title: extract_model_title(el),
            name:  extract_model_name(el),
            url:   extract_model_url(el) }
        end
      end
      models -= [nil, '']

      manufacturer[:models] = models

      params = {
          manufacturer_title: manufacturer[:title],
          manufacturer_name:  manufacturer[:name]
      }

      manufacturer_id = DatabaseManager.find_manufacturer_id(manufacturer[:name])
      puts "manuf_id:::#{manufacturer_id}"

      # if manufacturer_id.blank?
      #   puts 'gotcha'
      # else
      #   'nope nav!'
      # end

      manufacturer[:models] = get_model_body_types(manufacturer[:models], params)
      manufacturer
    end
    manufacturers
  end

  def self.get_model_body_types(models, params)
    models = models.each do |model|
      #TODO REMOVE AFTER IMAGE LOGIC
      puts model
      #next unless model[:name] == 'arnage'
      sleep 1

      next if model[:title] == nil || model[:title] == '' || model[:title] == ' ' || model[:title].nil?

      # get page
      doc        = Network.get_parsed_source(Url.parkers + model[:url])

      # get body types from page
      body_types = doc.css('div.header > h3')
      body_types = body_types.map { |el| { name: extract_model_body_type(el, model[:title]) } }

      #years
      years      = doc.css('h4')
      years      = years.map { |n| { year: n.text, link: n.css('a').attr('href').to_s } }

      years = CleanerForParkers.clean_empty_links(years)

      # TODO CAR IMAGE LOGIC
      CSV.open("full_list.csv", 'ab') do |writer|
        years.each do |year|
          begin
            doc2 = Network.get_parsed_source(Url.parkers + year[:link] + 'gallery')
          rescue Exception => e
            next
          end

          params[:model_title] = model[:title]
          params[:model_name]  = model[:name]
          params[:model_year]  = year[:year]

          image_elements = doc2.css('div#reviewGalleryNoScript div.categoryImages div ul li a')
          ParkersImages.get_images(params, writer, image_elements)
        end
      end

      model[:body_types] = body_types
      #model[:body_types] = get_model_years(model, params, doc)
      model
    end
    models
  end

  # get car years
  def self.get_model_years(model, params, doc)
    model[:body_types] = model[:body_types].each do |body_type|
      puts body_type
      sleep 1
      next if body_type == nil || body_type == '' || body_type == ' ' || body_type.nil?

      # get page
      years = doc.css('h4')

      years             = years.map { |n| { year: n.text, link: n.css('a').attr('href').to_s } }

      #clean body type years
      years             = CleanerForParkers.clean_empty_links(years)

      #assign years to body type hash
      body_type[:years] = years

      body_type[:years] = get_versions(body_type[:years], params)
      body_type
    end
    model[:body_types]
  end

  # get versions
  def self.get_versions(years, params)
    years = years.map do |year|
      puts year
      sleep 1

      next if year == nil || year == '' || year == ' ' || year.nil?

      year[:versions] = []

      doc      = Network.get_parsed_source(Url.parkers + year[:link])
      tr_items = doc.css('section.blueTab tr')

      tr_items.each do |tr_item|
        a = tr_item.css('a')
        next unless a.text == 'See Facts and Figures'

        link       = a.attr('href').value
        model_type = tr_item.at('p').text

        year[:versions] << { link: link, model_type: model_type }
      end

      year[:versions] = get_car_info(year[:versions])
      year
    end
    years
  end

  def self.get_car_info(versions)
    versions = versions.map do |version|
      puts version
      next if version == nil || version == '' || version == ' ' || version.nil?

      doc    = Network.get_parsed_source(Url.parkers + version[:link])

      # get 4 info boxes
      wraps  = doc.css('.fullWidth .halfWidth .contentArea').to_a.slice(0, 4)

      # values
      values = []

      # loop through
      wraps.each do |wrap|
        wrap.css('tr').to_a.each do |tr|
          values << { :name => tr.css('th').text, :value => tr.css('td').text }
        end
      end

      values            = CleanerForParkers.clean_details(values)
      version[:details] = values.flatten
      version
    end
    versions
  end

  private

  def self.extract_model_title(element)
    model_title = element.text.strip
    model_title
  end

  def self.extract_model_name(element)
    model_name = element.text.strip
    model_name = model_name.downcase.strip
    model_name = model_name.gsub(/\s/, '-').strip
    model_name
  end

  def self.extract_model_url(element)
    model_url = element.attr('href')
    model_url
  end

  def self.extract_model_body_type(element, model_title)
    model_body_type = element.text
    model_body_type = model_body_type.gsub(/#{model_title}/, '').strip
    model_body_type = model_body_type.downcase
    model_body_type
  end

  def self.extract_trim(element)
    model_trim = element.text

    if model_trim.empty? ||
        model_trim =~ /Facts/ ||
        model_trim =~ /\£/
      return false
    else
      model_trim
    end
  end

  def self.extract_trim_url(element)
    trim_url = element.css('a')

    if trim_url.empty?
      return false
    else
      trim_url.attr('href')
    end
  end
end
