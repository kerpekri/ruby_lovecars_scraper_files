#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../connections/url.rb'

class CarStylingStructure
  def self.get_models(manufacturers)
    manufacturers = manufacturers.each do |manufacturer|
      next if manufacturer[:title] == nil || manufacturer[:title] == '' || manufacturer[:title] == ' ' || manufacturer[:title].nil?

      sleep 1
      # get page
      doc            = Network.get_parsed_source(Url.car_styling_manufacturers + manufacturer[:url])
      model_elements = doc.css('div a.piclabel')

      models                = model_elements.map { |el| { title: extract_model_title(el, manufacturer[:title]),
                                                          name:  extract_model_name(el, manufacturer[:title]),
                                                          url:   extract_model_url(el.attr('href')) } }
      manufacturer[:models] = models

      params = {
          manufacturer_title: manufacturer[:title],
          manufacturer_name:  manufacturer[:name]
      }

      manufacturer[:models] = get_model_body_types(manufacturer[:models], params)
    end
  end

  def self.get_model_body_types(models, params)
    models = models.map do |model|
      next if model == nil || model == '' || model == ' ' || model.nil?

      #next unless model[:name] == 'cl-x'
      body_types = []
      body_types << { name: '-' }
      sleep 1

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

      doc            = Network.get_parsed_source(Url.car_styling_manufacturers + model_url)
      model_elements = doc.css('div.car div.col_1 h1')

      years = model_elements.map { |el| { year: extract_model_year(el) } }
      sleep 1

      params[:doc] = doc

      year[:years] = years
      year[:years] = start_image_logic(year[:years], params)
      year
    end
    years
  end

  def self.start_image_logic(year_elements, params)
    CSV.open("car_styling_files/full.csv", 'ab') do |writer|
      year_elements.each do |element|

        params[:model_year] = element[:year]
        sleep 1

        image_elements = params[:doc].css('div.block div.image img')
        GetCarStylingImages.get_images(params, writer, image_elements)
      end
    end
  end

  private

  def self.extract_model_title(element, manufacturer_title)
    model_title = element.css('span.l.cp')
    title       = model_title.text
    title       = title.gsub(/^\d{1,4}/, '').strip
    title       = title.gsub(/#{manufacturer_title}/, '').strip
    title
  end

  def self.extract_model_name(element, manufacturer_title)
    model_name = element.css('span.l.cp')
    name       = model_name.text
    name       = name.gsub(/^\d{1,4}/, '').strip
    name       = name.gsub(/#{manufacturer_title}/, '').strip
    name       = name.downcase
    name       = name.gsub(/\)/, '').strip
    name       = name.gsub(/\(/, '').strip
    name       = name.gsub(/\s/, '-').strip
    name
  end

  def self.extract_model_url(element)
    model_url = element
    model_url
  end

  def self.extract_model_year(element)
    model_year = element
    model_year = model_year.text.strip
    model_year = model_year.slice(0, 4).strip
    model_year = model_year + ' - ' + model_year
    model_year
  end
end
