#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../connections/url.rb'

class CarLogosStructure
  def self.get_models(manufacturers)
    manufacturers = manufacturers.map do |manufacturer|
      next if manufacturer[:name] =~ /\// || manufacturer[:name] == nil || manufacturer[:name] == '' || manufacturer[:name] == ' ' || manufacturer[:name].nil?

      # get page
      doc           = Network.get_parsed_source(manufacturer[:url])
      page_elements = doc.css('h2 ~ p').map do |element|
        extraced_info = extract_info_from_str(element, manufacturer[:name], manufacturer[:title])
        extraced_info ? extraced_info : nil
      end
      page_elements = page_elements.compact.uniq

      manufacturer[:models] = []
      page_elements.each do |page_element|
        next if page_element[:model_title] == nil || page_element[:model_title] == '' || page_element[:model_title] == ' ' || page_element[:model_title].nil? ||
            page_element[:year] == nil || page_element[:year] == '' || page_element[:year] == ' ' || page_element[:year].nil? ||
            page_element[:trim] == nil || page_element[:trim] == '' || page_element[:trim] == ' ' || page_element[:trim].nil?

        manufacturer_model_index = index_of_model_in_manufacturer(page_element[:model], manufacturer[:models])
        if manufacturer_model_index.nil?
          # veidojam new [{}]
          manufacturer[:models] << {
              title:     page_element[:model_title],
              name:      page_element[:model_name],
              body_type: [
                             {
                                 name:  '-',
                                 years: [
                                            {
                                                year:     page_element[:year].to_s.strip,
                                                versions: [
                                                              { model_type: page_element[:trim] }
                                                          ]
                                            }
                                        ]
                             }
                         ]
          }
        else
          #  konkrētais modelis
          manufacturer_model      = manufacturer[:models][manufacturer_model_index]

          # atrodu indexku modelim, ja vins ir atrast manufacturer
          index_if_year_in_models = index_of_year_in_models(manufacturer_model, manufacturer_model[:body_type][0][:years])

          #nav atrasts veidojam jaunu
          if index_if_year_in_models.nil?
            manufacturer[:models][manufacturer_model_index][:body_type][0][:years] << {
                year:     page_element[:year].to_s.strip,
                versions: [
                              { model_type: page_element[:trim] }
                          ]
            }
          end
          manufacturer[:models][manufacturer_model_index] = manufacturer_model
        end
        manufacturer
      end
      manufacturer
    end
  end

  private

  def self.index_of_model_in_manufacturer(page_element_model, models)
    model_index = nil
    models.each_with_index do |model, index|
      model_index = index if model[:name] == page_element_model
    end
    model_index
  end

  def self.index_of_year_in_models(manufacturer_model, years)
    year_index = nil
    years.each_with_index do |model, index|
      year_index = index if model[:name] == manufacturer_model
    end
    year_index
  end

  def self.extract_info_from_str(model_element, manufacturer_name, manufacturer_title)
    model_element = model_element.text.strip

    # model
    model_title   = model_element
    model_title   = model_title.gsub(/^\d{4}/, '').strip
    model_title   = model_title.gsub(manufacturer_title, '').strip
    model_title   = model_title.gsub(/\s\d{1}.\d{1}.*/, '').strip
    model_title   = model_title.gsub(/^-/, '').strip
    model_title   = model_title.gsub(/′$/, '').strip

    # model_name
    model_name    = model_element
    model_name    = model_name.gsub(/^\d{4}/, '').strip
    model_name    = model_name.downcase
    model_name    = model_name.gsub(manufacturer_name, '').strip
    model_name    = model_name.gsub(/\s\d{1}.\d{1}.*/, '').strip
    model_name    = model_name.gsub(/\s/, '-').strip

    # years
    year          = model_element
    year          = year.gsub(/\s.*/, '').strip
    year          = year.gsub(/ /, '').strip
    year          = year.downcase.gsub(manufacturer_name, '').strip

    if year =~ /^\d{1,4}/ && (year =~ /^19/ || year =~ /^20/)
      year
    else
      return nil
    end

    # trim
    trim = model_element
    trim = trim.gsub(/^\d{4}/, '').strip
    trim = trim.gsub(manufacturer_name, '').strip

    if trim =~ /\d{1}[.]\d{1}/
      trim = trim.gsub(/.*(?=(\d{1}[.]\d{1}))/, '').strip
      trim = trim.gsub(/(\d{1,} MY)/, '').strip
      trim = trim.gsub(/\(\)/, '').strip
      trim = trim.gsub(/\(/, '').strip
      trim = trim.gsub(/\)/, '').strip
    else
      return nil
    end

    if model_name.empty? || year.empty? || year.nil? || trim.empty? || trim.nil?
      return false
    else
      return { model_title: model_title, model_name: model_name, year: year + ' - ' + year, trim: trim }
    end

  end
end
