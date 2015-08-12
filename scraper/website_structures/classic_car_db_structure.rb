#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../connections/url.rb'

class ClassicCarDbStructure
  def self.get_models(manufacturers)
    manufacturers = manufacturers.each do |manufacturer|
      next if manufacturer[:title] == nil || manufacturer[:title] == '' || manufacturer[:title] == ' ' || manufacturer[:title].nil?

      begin
        # get page
        doc = Network.get_parsed_source(Url.classic_car_db_models + manufacturer[:url])
      rescue SocketError
        next
      rescue Mechanize::ResponseCodeError
        next
      end

      model_elements = doc.css('a.carmodel')

      models = model_elements.map do |el|
        urls = extract_model_url(el, manufacturer[:title])
        if urls
          {
              title: extract_model_title(el, manufacturer[:title]),
              name:  extract_model_name(el, manufacturer[:title]),
              url:   urls
          }
        end
      end
      models -= [nil, '']

      manufacturer[:models] = models
      manufacturer[:models] = get_model_body_types(manufacturer[:models])
      manufacturer
    end
    manufacturers
  end

  def self.get_model_body_types(models)
    models = models.map do |model|
      next if model == nil || model == '' || model == ' ' || model.nil?

      #extract_body_type(model[:name])
      body_types = []
      body_types << { name: '-' }

      model[:body_types] = body_types
      model[:body_types] = get_model_years(model[:body_types], model[:url])
      model
    end
    models
  end

  def self.get_model_years(body_types, model_url)
    years = body_types.each do |year|
      next if year == nil || year == '' || year == ' ' || year.nil?

      doc            = Network.get_parsed_source(Url.classic_car_db_models + model_url)
      model_elements = doc.css('td.title')

      years = model_elements.map { |el| { year: extract_model_year(el) } }

      year[:years] = years
      year[:years] = get_versions(year[:years], doc)
      year
    end
    years
  end

  def self.get_versions(years, doc)
    versions = years.map do |version|
      next if version == nil || version == '' || version == ' ' || version.nil?

      body_types = []
      body_types << { model_type: '-' }

      version[:versions] = body_types
      version[:versions] = get_car_info(version[:versions], doc)
      version
    end
    versions
  end

  def self.get_car_info(versions, doc)
    details = versions.map do |detail|
      next if detail == nil || detail == '' || detail == ' ' || detail.nil?

      info_elements = doc.css('div.spec')

      detail_names  = info_elements.css('td.label')
      detail_values = info_elements.css('td.data')

      info = detail_names.map.with_index do |el, i|
        info_check = extract_detail_values(detail_values[i])
        if info_check
          {
              name:  extract_detail_names(el),
              value: extract_detail_values(detail_values[i])
          }
        end
      end
      info -= [nil, '']

      detail[:details] = info
      detail
    end
    details
  end

  private

  def self.extract_model_title(element, manufacturer_title)
    model_title = element.text
    title       = model_title.gsub(/^\d{1,4}/, '').strip
    title       = title.gsub(/#{manufacturer_title}/, '').strip
    title       = title.gsub(/^-/, '').strip
    title       = title.gsub(/-$/, '').strip
    title       = title.gsub(/Sportback$/, '').strip
    title       = title.gsub(/Hybrid$/, '').strip
    title       = title.gsub(/Kombi$/, '').strip
    title       = title.gsub(/Combi$/, '').strip
    title       = title.gsub(/Cab$/, '').strip
    title       = title.gsub(/Wagon$/, '').strip
    title       = title.gsub(/Cargo$/, '').strip
    title       = title.gsub(/Liftback$/, '').strip
    title       = title.gsub(/Cabrio$/, '').strip
    title       = title.gsub(/Cabriolet$/, '').strip
    title       = title.gsub(/Sport Wagon$/, '').strip
    title       = title.gsub(/Limousine$/, '').strip
    title       = title.gsub(/Coupe$/, '').strip
    title       = title.gsub(/Truck$/, '').strip
    title       = title.gsub(/Roadster$/, '').strip
    title       = title.gsub(/Van$/, '').strip
    title       = title.gsub(/Hatchback$/, '').strip
    title       = title.gsub(/Touring$/, '').strip
    title       = title.gsub(/Pickup$/, '').strip
    title       = title.gsub(/Suv$/, '').strip
    title       = title.gsub(/Convertible$/, '').strip
    title       = title.gsub(/Estate$/, '').strip
    title       = title.gsub(/Sedan$/, '').strip
    title       = title.gsub(/Speedster/, '').strip
    title       = title.gsub(/Saloon$/, '').strip
    title       = title.gsub(/or/, '').strip
    title       = title.gsub(/-$/, '').strip
    title
  end


  def self.extract_model_name(element, manufacturer_title)
    model_name = element.text
    name       = model_name.gsub(/^\d{1,4}/, '').strip
    name       = name.gsub(/#{manufacturer_title}/, '').strip
    name       = name.downcase
    name       = name.gsub(/\)/, '').strip
    name       = name.gsub(/\(/, '').strip
    name       = name.gsub(/\s/, '-').strip
    name       = name.gsub(/^-/, '').strip
    name       = name.gsub(/-$/, '').strip
    name       = name.gsub(/sportback$/, '').strip
    name       = name.gsub(/hybrid$/, '').strip
    name       = name.gsub(/kombi$/, '').strip
    name       = name.gsub(/combi$/, '').strip
    name       = name.gsub(/cab$/, '').strip
    name       = name.gsub(/wagon$/, '').strip
    name       = name.gsub(/cargo$/, '').strip
    name       = name.gsub(/speedster/, '').strip
    name       = name.gsub(/liftback$/, '').strip
    name       = name.gsub(/cabrio$/, '').strip
    name       = name.gsub(/cabriolet$/, '').strip
    name       = name.gsub(/sport-wagon$/, '').strip
    name       = name.gsub(/limousine$/, '').strip
    name       = name.gsub(/coupe$/, '').strip
    name       = name.gsub(/truck$/, '').strip
    name       = name.gsub(/roadster$/, '').strip
    name       = name.gsub(/van$/, '').strip
    name       = name.gsub(/hatchback$/, '').strip
    name       = name.gsub(/touring$/, '').strip
    name       = name.gsub(/pickup$/, '').strip
    name       = name.gsub(/suv$/, '').strip
    name       = name.gsub(/convertible$/, '').strip
    name       = name.gsub(/estate$/, '').strip
    name       = name.gsub(/sedan$/, '').strip
    name       = name.gsub(/saloon$/, '').strip
    name       = name.gsub(/or/, '').strip
    name       = name.gsub(/-$/, '').strip
    name       = name.gsub(/-$/, '').strip
    name
  end

  def self.extract_model_url(element, manufacturer_title)
    model_text = element.text.strip
    model_url  = element.attr('href')

    model_url = model_url.gsub(/^\.\./, '')

    if model_text.include?(manufacturer_title)
      return model_url
    else
      false
    end
  end

  def self.extract_body_type(model_name)
    if model_name.downcase.include?('saloon')
      body_type = 'saloon'
    elsif model_name.downcase.include?('sedan')
      body_type = 'sedan'
    elsif model_name.downcase.include?('estate')
      body_type = 'estate'
    elsif model_name.downcase.include?('convertible')
      body_type = 'convertible'
    elsif model_name.downcase.include?('suv')
      body_type = 'suv'
    elsif model_name.downcase.include?('pickup')
      body_type = 'pickup'
    elsif model_name.downcase.include?('hatchback')
      body_type = 'hatchback'
    elsif model_name.downcase.include?('van')
      body_type = 'van'
    elsif model_name.downcase.include?('roadster')
      body_type = 'roadster'
    elsif model_name.downcase.include?('truck')
      body_type = 'truck'
    elsif model_name.downcase.include?('coupe')
      body_type = 'coupe'
    elsif model_name.downcase.include?('limousine')
      body_type = 'limousine'
    elsif model_name.downcase.include?('sport-wagon')
      body_type = 'sport-wagon'
    elsif model_name.downcase.include?('cabrio')
      body_type = 'cabrio'
    elsif model_name.downcase.include?('liftback')
      body_type = 'liftback'
    elsif model_name.downcase.include?('cargo')
      body_type = 'cargo'
    elsif model_name.downcase.include?('wagon')
      body_type = 'wagon'
    elsif model_name.downcase.include?('cab')
      body_type = 'cab'
    elsif model_name.downcase.include?('station-wagon')
      body_type = 'station-wagon'
    elsif model_name.downcase.include?('combi')
      body_type = 'combi'
    elsif model_name.downcase.include?('kombi')
      body_type = 'kombi'
    elsif model_name.downcase.include?('hybrid')
      body_type = 'hybrid'
    elsif model_name.downcase.include?('sportback')
      body_type = 'sportback'
    else
      body_type = '-'
    end
    body_type
  end

  def self.extract_model_year(element)
    model_year = element.text.strip
    model_year = model_year.slice(0, 4).strip
    model_year = model_year + ' - ' + model_year
    model_year
  end

  def self.extract_detail_names(element)
    detail_names = element.text.strip
    detail_names
  end

  def self.extract_detail_values(element)
    detail_values = element.text.strip

    if detail_values.empty? ||
        detail_values =~ /Unknown/ ||
        detail_values =~ /applicable/ ||
        detail_values =~ /Not applic/
      return false
    else
      detail_values
    end
  end
end
