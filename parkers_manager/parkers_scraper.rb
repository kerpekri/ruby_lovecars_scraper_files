#!/usr/bin/env ruby
# encoding: utf-8

require 'rubygems'
require 'mechanize'
require 'nokogiri'
require 'open-uri'
require 'active_record'
require 'mysql2'
require 'active_support/all'
require 'logger'
require 'json'
require 'resolv-replace.rb'

require_relative 'website_structures/parkers_structure.rb'
require_relative 'website_structures/conceptcarz_structure.rb'
require_relative 'website_structures/carfolio_structure.rb'
require_relative 'website_structures/car_logos_structure.rb'
require_relative 'website_structures/caricos_structure.rb'
require_relative 'website_structures/car_styling_structure.rb'
require_relative 'website_structures/classic_car_db_structure.rb'
require_relative 'connections/network.rb'
require_relative 'website_structures/cleaners/cleaner_for_parkers.rb'
require_relative 'connections/url.rb'

class ParkersScraper
  def self.get_parkers_info
    form                = parse_source_link.css('form')
    manufacturer_fields = form.css('[name="ctl00$contentHolder$topFullWidthContent$ctlManufacturerModelDropdownsNew$ddlManufacturer_Control"] option')
    get_parkers_manufacturers(manufacturer_fields)
  end

  private

  def self.get_parkers_manufacturers(manufacturer_fields)

    @manufacturers = []

    manufacturer_fields.map do |field|
      manufacturer_title = find_manufacturer_title(field)
      manufacturer_name  = find_manufacturer_name(field)

      next if remove_specific_values(manufacturer_name)

      #TODO REMOVE AFTER CAR IMAGE DOWN LOGIC
      next unless manufacturer_name.strip == 'audi'

      create_manufacturers_array(manufacturer_title, manufacturer_name)
      add_sleep_time
      scrap_models(@manufacturers)
      #create_result_json
    end
  end

  def self.create_result_json
    @result.each do |element|
      next if element == nil || element == '' || element == ' ' || element.nil?

      File.open("parkers_jsons/#{element[:name]}.json", 'w') do |f|
        f.write element.to_json
      end
    end
  end

  def self.create_manufacturers_array(title, name)
    @manufacturers << { title: title, name: name }
  end

  def self.scrap_models(manufacturers)
    @result = ParkersStructure.get_parkers_models(manufacturers)
  end

  def self.add_sleep_time
    sleep 2
  end

  def self.remove_specific_values(manufacturer_name)
    manufacturer_name.strip == 'select-a-manufacturer'
  end

  def self.parse_source_link
    Network.get_parsed_source(Url.parkers)
  end

  def self.find_manufacturer_title(field)
    field.text.strip
  end

  def self.find_manufacturer_name(field)
    manufacturer_name = field.text.downcase.strip
    manufacturer_name = manufacturer_name.gsub(/\//, '-').strip
    manufacturer_name = manufacturer_name.gsub(/\s/, '-').strip
    manufacturer_name = manufacturer_name.gsub(/\//, '-').strip
    manufacturer_name
  end
end

RootScraper.get_parkers_info


