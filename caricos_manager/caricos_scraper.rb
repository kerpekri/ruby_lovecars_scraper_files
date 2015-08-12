#!/usr/bin/env ruby
# encoding: utf-8
require 'rubygems'
require 'mechanize'
require 'nokogiri'
require 'open-uri'
require 'pry'
require 'active_record'
require 'mysql2'
require 'active_support/all'
require 'logger'
require 'csv'
require 'json'
require 'resolv-replace.rb'
require 'fileutils'

require_relative 'website_structures/parkers_structure.rb'
require_relative 'website_structures/parkers_images.rb'
require_relative 'website_structures/conceptcarz_structure.rb'
require_relative 'website_structures/carfolio_structure.rb'
require_relative 'website_structures/car_logos_structure.rb'
require_relative 'website_structures/caricos_structure.rb'
require_relative 'website_structures/car_styling_structure.rb'
require_relative 'website_structures/classic_car_db_structure.rb'
require_relative 'connections/network.rb'
require_relative 'website_structures/cleaners/cleaner_for_parkers.rb'
require_relative 'connections/url.rb'
require_relative 'active_record_relations.rb'

class RootScraper
  def self.get_caricos_info
    doc                 = Network.get_parsed_source(Url.caricos_manufacturers)
    manufacturer_fields = doc.css('div#hdmake ul li a')
    get_caricos_manufacturers(manufacturer_fields)
  end

  private

  def self.get_caricos_manufacturers(manufacturer_fields)

    @manufacturers = []

    manufacturer_fields.map do |manufacturer_field|

      @manufacturers << {
          title: get_manufacturer_title(manufacturer_field),
          name:  get_manufacturer_name(manufacturer_field),
          url:   get_manufacturer_link(manufacturer_field)
      }
      add_sleep_time
      @result = CaricosStructure.get_models(@manufacturers)
      # create_result_json
    end
  end

  def self.create_result_json
    @result.each do |element|
      next if element == nil || element == '' || element == ' ' || element.nil?

      File.open("caricos_jsons/#{element[:name]}.json", 'w') do |f|
        f.write element.to_json
      end
    end
  end

  def self.add_sleep_time
    sleep 2
  end

  def self.get_manufacturer_title(field)
    field.text.strip
  end

  def self.get_manufacturer_name(field)
    name = field.text.strip
    name = name.downcase
    name = name.gsub(/\s/, '-').strip
    name
  end

  def self.get_manufacturer_link(field)
    field.attr('href').strip
  end
end

RootScraper.get_caricos_info



