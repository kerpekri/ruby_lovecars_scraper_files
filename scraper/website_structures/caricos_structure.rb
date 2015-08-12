#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../connections/url.rb'

class CaricosStructure
  def self.get_models(manufacturers)
    manufacturers = manufacturers.each do |manufacturer|
      #TODO REMOVE AFTER IMAGE DOWNLOAD LOGIC
      next unless manufacturer[:name] == 'alfa-romeo'
      #puts manufacturer
      next if manufacturer[:title] == nil || manufacturer[:title] == '' || manufacturer[:title] == ' ' || manufacturer[:title].nil?

      #sleep 1
      # get page
      doc            = Network.get_parsed_source(manufacturer[:url])
      model_elements = doc.css('div.model a')
      models         = model_elements.map { |el| { title: extract_model_title(el, manufacturer[:title]),
                                                   name:  extract_model_name(el, manufacturer[:title]),
                                                   url:   extract_url(el) } }

      params = {
          manufacturer_title: manufacturer[:title],
          manufacturer_name:  manufacturer[:name]
      }

      manufacturer[:models] = models
      manufacturer[:models] = get_model_body_types(manufacturer[:models], params)
      manufacturer
    end
    manufacturers
  end

  def self.get_model_body_types(models, params)
    models = models.map do |model|
      #TODO REMOVE AFTER IMAGE DOWNLOAD LOGIC
      next unless model[:name] == 'giulietta-sprint'
      next if model == nil || model == '' || model == ' ' || model.nil?

      body_types = []
      body_types << { name: '-' }
      #sleep 1

      params[:model_title] = model[:title]
      params[:model_name]  = model[:name]

      model[:body_types] = body_types
      model[:body_types] = get_model_years(model[:body_types], model[:url], params)
      model
    end
    models
  end

  def self.get_model_years(body_types, model_url, params)
    years = body_types.each do |year|
      next if year == nil || year == '' || year == ' ' || year.nil?

      doc                = Network.get_parsed_source(model_url)
      model_elements     = doc.css('div h1')
      years              = model_elements.map { |elem| { year: extract_model_year(elem) } }
      #sleep 1

      params[:model_url] = model_url

      year[:years] = years
      # Can't be scraped, because of html -> Js image loading logic.
      #year[:years] = start_image_logic(year[:years], params)
      year
    end
    years
  end

  def self.start_image_logic(years, params)
    CSV.open("caricos_files/full.csv", 'ab') do |writer|
      years.each do |year|
        index               = 1
        # sleep 1

        params[:model_year] = year[:year]

        doc            = Network.get_parsed_source(params[:model_url] + "1920x1080/#{index}.html")
        image_elements = doc.css('img#wallpaper')

        GetCaricosImages.get_images(params, writer, image_elements)
      end
    end
  end

  private

  def self.extract_model_title(model_elements, manufacturer_title)
    models = model_elements.css('span.ttl').text
    models = models.gsub(/#{manufacturer_title}/, '').strip
    models = models.gsub(/^\d{1,4}\s+/, '').strip
    models
  end

  def self.extract_url(element)
    urls = element.attr('href').to_s
    urls
  end

  def self.extract_model_name(model_elements, manufacturer_title)
    models = model_elements.css('span.ttl').text
    models = models.gsub(/#{manufacturer_title}/, '').strip
    models = models.gsub(/^\d{1,4}\s+/, '').strip.downcase
    models = models.gsub(/\s/, '-').strip
    models = models.gsub(/\//, '-').strip
    models
  end

  def self.extract_model_year(element)
    year = element.text.strip
    year = year.slice(0, 4).strip
    year = year + ' - ' + year
    year
  end
end
