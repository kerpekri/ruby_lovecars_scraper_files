#!/usr/bin/env ruby
# encoding: utf-8
class EdmundsStructure
  def self.get_models(manufacturer_info)
    manufacturer_info.each do |manufacturer|
      next if manufacturer[:name] == nil ||
          manufacturer[:name] == '' ||
          manufacturer[:name] == ' ' ||
          manufacturer[:name].nil?
      sleep 1

      begin
        # get page
        doc = Network.get_parsed_source(Url.edmunds_webpage + manufacturer[:name])
      rescue SocketError
        next
      rescue Mechanize::ResponseCodeError
        next
      end

      model_elements = doc.css('p.name a')

      models = model_elements.map do |el|
        model_title = extract_model_title(el, manufacturer[:title])

        { title: model_title,
          name:  extract_model_name(model_title),
          url:   extract_model_url(el)
        }
      end

      manufacturer[:models] = models

      params = {
          manufacturer_title: manufacturer[:title],
          manufacturer_name:  manufacturer[:name]
      }

      manufacturer[:models] = get_model_body_types(manufacturer[:models], params)
    end
  end

  def self.get_model_body_types(models, params)
    models.each do |model|
      #next unless model[:name] == 'mdx'
      next if model[:title] == nil || model[:title] == '' || model[:title] == ' ' || model[:title].nil?
      sleep 1

      doc           = Network.get_parsed_source(Url.edmunds_webpage + model[:url])
      year_elements = doc.css('p.name a')

      years = year_elements.map do |el|

        year_title = extract_year_title(el)
        {
            year_title: year_title,
            year_name:  extract_year_name(year_title),
            year_link:  extract_year_link(el)
        }
      end

      model[:years] = years

      params[:model_title] = model[:title]
      params[:model_name]  = model[:name]

      model[:years] = get_photo_links(model[:years], params)
    end
  end

  def self.get_photo_links(years, params)
    years.each do |year|
      #next unless year[:year_title] == '2016 - 2016'
      next if year[:year_title] == nil || year[:year_title] == '' || year[:year_title] == ' ' || year[:year_title].nil?
      sleep 1

      doc        = Network.get_parsed_source(year[:year_link])
      photo_link = doc.css('a#photo-tab')

      params[:model_year] = year[:year_title]

      if photo_link.empty?
        next
      else
        start_image_logic(photo_link.attr('href').to_s, params)
      end
    end
  end

  def self.start_image_logic(image_link, params)
    CSV.open("edmunds_files/full.csv", 'ab') do |writer|
      image_doc      = Network.get_parsed_source(Url.edmunds_webpage + image_link)
      image_elements = image_doc.css('a.thumb-link img')
      sleep 1
      GetEdmundsImages.get_images(params, writer, image_elements)
    end
  end

  private

  def self.extract_year_title(element)
    year_title = element.text
    year_title = year_title.slice(0, 4)
    year_title = year_title + ' - ' + year_title
    year_title
  end

  def self.extract_year_name(element)
    year_name = element.downcase.strip
    year_name = year_name.gsub(/\s-\s/, '-').strip
    year_name
  end

  def self.extract_year_link(element)
    year_link = element.attr('href')
    year_link = Url.edmunds_webpage + year_link
    year_link
  end

  def self.extract_model_title(element, manufacturer_title)
    model_title = element.text.strip
    model_title = model_title.gsub(manufacturer_title, '').strip
    model_title = model_title.gsub(/Cross Country Wagon$/, '').strip
    model_title = model_title.gsub(/w\/Summer Tires$/, '').strip
    model_title = model_title.gsub(/w\/Navigation$/, '').strip
    model_title = model_title.gsub(/w\/Navigation and Summer Tires$/, '').strip
    model_title = model_title.gsub(/Gran Coupe Sedan$/, 'Gran Coupe').strip
    model_title = model_title.gsub(/Electric Drive Hatchback$/, '').strip
    model_title = model_title.gsub(/Express Cargo Van$/, '').strip
    model_title = model_title.gsub(/Crew Cab$/, '').strip
    model_title = model_title.gsub(/Convertible Diesel$/, '').strip
    model_title = model_title.gsub(/Coupe Convertible$/, 'Coupe').strip
    model_title = model_title.gsub(/CrossCabriolet SUV$/, '').strip
    model_title = model_title.gsub(/Regular Cab$/, '').strip
    model_title = model_title.gsub(/Cargo Van$/, '').strip
    model_title = model_title.gsub(/City Minivan$/, '').strip
    model_title = model_title.gsub(/Double Cab$/, '').strip
    model_title = model_title.gsub(/Sport Wagon$/, '').strip
    model_title = model_title.gsub(/Hybrid Sedan$/, '').strip
    model_title = model_title.gsub(/Extended Cab$/, '').strip
    model_title = model_title.gsub(/SuperCrew$/, '').strip
    model_title = model_title.gsub(/Wagon Van$/, '').strip
    model_title = model_title.gsub(/Cargo Diesel$/, '').strip
    model_title = model_title.gsub(/Hybrid Sedan$/, '').strip
    model_title = model_title.gsub(/Natural Gas$/, '').strip
    model_title = model_title.gsub(/Convertible IPL$/, '').strip
    model_title = model_title.gsub(/Coupe IPL$/, '').strip
    model_title = model_title.gsub(/Quad Cab$/, '').strip
    model_title = model_title.gsub(/Mega Cab$/, '').strip
    model_title = model_title.gsub(/King Cab$/, '').strip
    model_title = model_title.gsub(/Window Van$/, '').strip
    model_title = model_title.gsub(/SUV$/, '').strip
    model_title = model_title.gsub(/suv$/, '').strip
    model_title = model_title.gsub(/SuperCab$/, '').strip
    model_title = model_title.gsub(/Sedan$/, '').strip
    model_title = model_title.gsub(/Electric$/, '').strip
    model_title = model_title.gsub(/Energi$/, '').strip
    model_title = model_title.gsub(/ALL4$/, '').strip
    model_title = model_title.gsub(/Diesel$/, '').strip
    model_title = model_title.gsub(/Minivan$/, '').strip
    model_title = model_title.gsub(/Van$/, '').strip
    model_title = model_title.gsub(/Cargo$/, '').strip
    model_title = model_title.gsub(/Coupe$/, '').strip
    model_title = model_title.gsub(/Convertible$/, '').strip
    model_title = model_title.gsub(/Wagon$/, '').strip
    model_title = model_title.gsub(/Hybrid$/, '').strip
    model_title = model_title.gsub(/Hatchback$/, '').strip
    model_title
  end

  def self.extract_model_name(title)
    model_name = title.downcase.strip
    model_name = model_name.gsub(/\s/, '-').strip
    model_name
  end

  def self.extract_model_url(element)
    model_url = element.attr('href')
    model_url
  end
end
