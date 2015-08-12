#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../connections/url.rb'

class CarFolioStructure
  def self.get_models(manufacturers)
    manufacturers = manufacturers.each do |manufacturer|
      next if manufacturer[:models] == nil || manufacturer[:models] == '' || manufacturer[:models] == ' ' || manufacturer[:models].nil?

      # get page
      doc            = get_parsed_source(Url.car_folio_spec + manufacturer[:url])
      model_elements = doc.css('a.addstable')
      clean_models   = clear_models(model_elements)

      manufacturer[:models] = clean_models.map { |element| { title: extract_title(element),
                                                             name:  extract_name(element),
                                                             link:  element.attr('href').to_s } }

      manufacturer[:models] = get_model_body_types(manufacturer[:models], manufacturer[:url])
      manufacturer
    end
    manufacturers
  end

  def self.get_model_body_types(models, manufacturer_url)
    models = models.map do |model|
      next if model == nil || model == '' || model == ' ' || model.nil?

      # get page
      doc                = get_parsed_source(Url.car_folio_models + model[:link])
      body_type_elements = doc.css('tbody tr td').first.text
      body_type_arr      = []

      body_types = { name: body_type_elements }
      body_type_arr << body_types

      model[:body_types] = body_type_arr
      model[:body_types] = get_model_years(model[:body_types], model[:link], manufacturer_url)
      model
    end
    models
  end

  def self.get_model_years(body_types, model_url, manufacturer_url)
    years = body_types.each do |body_type|
      next if body_type == nil || body_type == '' || body_type == ' ' || body_type.nil?

      doc            = get_parsed_source(Url.carfolio_years + model_url)
      model_elements = doc.css('span.modelyear')

      if model_elements.empty?
        model_elements = doc.css('span.Year')
      end

      years = clear_model_years(model_elements)
      if years.nil?
        next
      else
        body_type[:years] = years.map { |element| { year: element } }
      end

      body_type[:years] = get_versions(body_type[:years], doc)
      body_type
    end
    years
  end

  # get versions
  def self.get_versions(years, doc)
    versions = years.each do |year|
      next if year == nil || year == '' || year == ' ' || year.nil?

      model_elements = doc.css('div.inner dl')
      trims          = get_engine_size(model_elements)

      year[:versions] = trims.map { |element| { model_type: element } }
      year[:versions] = get_car_info(year[:versions], doc)
      year
    end
    versions
  end

  def self.get_car_info(versions, doc)
    details = versions.map do |version|
      next if version == nil || version == '' || version == ' ' || version.nil?

      model_elements = doc.css('table.specs tbody')

      # values
      values         = []

      # loop through
      model_elements.each do |wrap|
        next if wrap == nil || wrap == '' || wrap == ' ' || wrap.nil?

        wrap.css('tr').to_a.each do |tr|
          next if (tr.css('td').empty? || tr.css('th').empty?)
          name  = clear_name_tr(tr)
          value = clear_value_tr(tr)
          values << { name: name, value: value } unless (name.nil? || value.nil?)
        end
      end

      version[:details] = values
      version
    end
    details
  end

  private

  def self.clear_models(model_elements)
    valid_links = []

    model_elements.each do |model_element|
      next if (model_element.attr('href') =~ /^\/specifications/)
      valid_links << model_element
    end
    valid_links
  end

  def self.extract_title(element)
    title = element.css('span.model.name').text.strip
    title
  end

  def self.extract_name(element)
    name = element.css('span.model.name').text

    begin
      name = name.downcase
      name = name.gsub(/\s/, '-').strip
      name = name.gsub(/\./, '-').strip
    rescue ArgumentError
      return
    end

    name
  end

  def self.extract_model_year(element)
    year = element.css('span.Year').text.strip
  end

  def self.extract_model_type(element)
    title = element.css('span.model.name').text.strip
    title
  end

  def self.get_engine_size(element)
    trims = []
    trim  = element.css('dd').map do |y|
      next unless y.text =~ /litre/
      trim_details = y.text.strip
      trims << trim_details
    end
    trims
  end

  def self.clear_model_years(model_elements)
    years = []

    if model_elements.empty?
      return nil
    else
      year = model_elements.first.text
    end

    year = year.gsub(/MY/, '').strip
    years << year + ' - ' + year
    years
  end

  def self.clear_name_tr(element)
    details = element.css('th').text.strip

    if details.empty? || details =~ /No information available/ || details =~ /N\/A/ || details =~ /Carfolio/
      return nil
    else
      details
    end
    details
  end

  def self.clear_value_tr(element)
    details = element.css('td strong').first

    if details.nil?
      trim_detail = element.css('td').first.text.strip
    else
      trim_detail = element.css('td strong').first.text.strip
    end

    if trim_detail.empty? ||
        trim_detail =~ /No information available/ ||
        trim_detail =~ /N\/A/ ||
        trim_detail =~ /Carfolio/ ||
        trim_detail =~ / /
      return nil
    else
      trim_detail
    end
    trim_detail
  end

  def self.get_parsed_source(url)
    agent                  = Mechanize.new
    agent.user_agent_alias = 'Mac Safari'
    page_source            = agent.get(url).body
    doc                    = Nokogiri.parse(page_source)
    doc
  end
end
