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
require_relative 'website_structures/get_caricos_images.rb'
require_relative 'website_structures/get_edmunds_images.rb'
require_relative 'website_structures/conceptcarz_structure.rb'
require_relative 'website_structures/carfolio_structure.rb'
require_relative 'website_structures/car_logos_structure.rb'
require_relative 'website_structures/caricos_structure.rb'
require_relative 'website_structures/car_styling_structure.rb'
require_relative 'website_structures/classic_car_db_structure.rb'
require_relative 'website_structures/edmunds_structure.rb'
require_relative 'connections/network.rb'
require_relative 'website_structures/cleaners/cleaner_for_parkers.rb'
require_relative 'connections/url.rb'
require_relative 'active_record_relations.rb'

class RootScraper
  def self.get_parkers_information
    doc                 = Network.get_parsed_source(Url.parkers)

    # get first form
    form                = doc.css('form')
    manufacturer_fields = form.css('[name="ctl00$contentHolder$topFullWidthContent$ctlManufacturerModelDropdownsNew$ddlManufacturer_Control"] option')

    manufacturer_fields.map do |manufacturer_field|
      manufacturer_title = find_manufacturer_title(manufacturer_field)
      manufacturer_name  = find_manufacturer_name(manufacturer_field)

      next if manufacturer_name.strip == 'select-a-manufacturer'

      #TODO REMOVE AFTER CAR IMAGE DOWN LOGIC
      next if manufacturer_name.strip == 'abarth' ||
          manufacturer_name.strip == 'alfa-romeo' ||
          manufacturer_name.strip == 'aston-martin' ||
          manufacturer_name.strip == 'audi'
      #next unless manufacturer_name.strip == 'alfa-romeo'

      manufacturers = []
      manufacturers << { title: manufacturer_title, name: manufacturer_name } unless (manufacturer_name == 'select-a-manufacturer')

      sleep 1

      @result = ParkersStructure.get_models(manufacturers)

      #puts @result

      # @result.each do |result|
      #   next if result == nil || result == '' || result == ' ' || result.nil?
      #   # Write in Json file
      #   File.open("parkers_jsons/#{result[:name]}.json", 'w') do |f|
      #     f.write result.to_json
      #   end
      # end
    end
  end

  def self.conceptcarz_manufacturers
    doc                 = Network.get_parsed_source(Url.conceptcarz)
    manufacturer_fields = doc.css('table td li a')

    manufacturer_fields.map do |manufacturer_field|
      manufacturer_links = manufacturer_field.attr('href')
      manufacturers      = extract_manufacturer_from_url(manufacturer_links)
      links              = []
      links << manufacturer_links
      manufacturers = links.map { |link| { title: manufacturers, name: manufacturers.downcase, url: link } }

      sleep 2

      @result = ConceptcarzStructure.get_models(manufacturers)

      #puts @result

      @result.each do |result|
        next if result == nil || result == '' || result == ' ' || result.nil?
        # Write in Json file
        File.open("conceptcarz_jsons/#{result[:name]}.json", 'w') do |f|
          f.write result.to_json
        end
      end
    end
  end

  def self.car_logos_manufacturers
    doc                 = Network.get_parsed_source(Url.car_logos_manufacturers)
    manufacturer_fields = doc.css('table td a')

    manufacturer_fields.map do |manufacturer_field|
      manufacturer_title = extract_manufacturer_title(manufacturer_field)
      manufacturer_name  = extract_manufacturer_name(manufacturer_field)
      manufacturer_link  = manufacturer_field.attr('href').strip

      manufacturers = []
      manufacturers << { title: manufacturer_title, name: manufacturer_name, url: manufacturer_link }

      sleep 2

      @result = CarLogosStructure.get_models(manufacturers)

      puts @result

      @result.each do |result|
        next if result == nil || result == '' || result == ' ' || result.nil?
        # Write in Json file
        File.open("car_logos_jsons/#{result[:name]}.json", 'w') do |f|
          f.write result.to_json
        end
      end
    end
  end

  def self.car_folio_manufacturers
    doc                 = Network.get_parsed_source(Url.car_folio_spec)
    manufacturer_fields = doc.css('li.m a.man')

    manufacturer_fields.map do |manufacturer_field|
      manufacturer_name = manufacturer_field.css('strong').text.strip.gsub(/\s/, '-').strip
      manufacturer_link = manufacturer_field.attr('href').strip

      manufacturers = []
      #manufacturers << {title: manufacturer_name.gsub(/-/, ' ').strip, name: manufacturer_name.downcase.strip, url: manufacturer_link}

      sleep 1

      @result = CarFolioStructure.get_models(manufacturers)

      #puts @result

      puts 'abcd'

      # manufacturers.each do |result|
      #   next if result == nil || result == '' || result == ' ' || result.nil?
      #   # Write in Json file
      #   File.open("carfolio_jsons/#{result[:name]}.json", 'w') do |f|
      #     f.write result.to_json
      #   end
      # end
    end
  end

  def self.get_caricos_manufacturers
    doc        = Network.get_parsed_source(Url.caricos_manufacturers)
    #manufacturer_fields = doc.css('div#hdmake ul li a')

    image_link = "http://media.ed.edmunds-media.com/acura/ilx/2016/oem/2016_acura_ilx_sedan_technology-plus-package_rq_oem_1_600.jpg"
    puts Mechanize.new.get(image_link).save
    #"#{full_path}"

    # manufacturer_fields.map do |manufacturer_field|
    #   manufacturer_name = manufacturer_field.text.strip
    #   manufacturer_link = manufacturer_field.attr('href').strip
    #
    #   manufacturers = []
    #   manufacturers << { title: manufacturer_name, name: manufacturer_name.downcase.gsub(/\s/, '-').strip, url: manufacturer_link }
    #
    #   #sleep 1
    #
    #   #@result = CaricosStructure.get_models(manufacturers)
    #
    #   #puts @result
    #
    #   # manufacturers.each do |result|
    #   #   next if result == nil || result == '' || result == ' ' || result.nil?
    #   #   # Write in Json file
    #   #   File.open("caricos_jsons/#{result[:name]}.json", 'w') do |f|
    #   #     f.write result.to_json
    #   #   end
    #   # end
    # end
  end

  def self.car_styling_manufacturers
    doc                 = Network.get_parsed_source(Url.car_styling_manufacturers)
    manufacturer_fields = doc.css('div#ib_manufacturers a')

    manufacturer_fields.map do |manufacturer_field|
      manufacturer_title = clear_manufacturer_title(manufacturer_field)
      manufacturer_name  = clear_manufacturer_name(manufacturer_field)
      manufacturer_link  = manufacturer_field.attr('href').strip

      manufacturers = []
      manufacturers << { title: manufacturer_title, name: manufacturer_name, url: manufacturer_link }

      sleep 2

      @result = CarStylingStructure.get_models(manufacturers)

      puts @result

      manufacturers.each do |result|
        next if result == nil || result == '' || result == ' ' || result.nil?
        # Write in Json file
        File.open("car_styling_jsons/#{result[:name]}.json", 'w') do |f|
          f.write result.to_json
        end
      end
    end
  end

  def self.classic_car_db_manufacturers
    doc                 = Network.get_parsed_source(Url.classic_car_db_manufacturers)
    manufacturer_fields = doc.css('table tr td a.carMakeLink')

    manufacturer_fields.map do |manufacturer_field|
      manufacturer_title = get_manufacturer_title(manufacturer_field)
      manufacturer_name  = get_manufacturer_name(manufacturer_field)
      manufacturer_link  = manufacturer_field.attr('href').strip

      manufacturers = []
      manufacturers << { title: manufacturer_title, name: manufacturer_name, url: manufacturer_link }

      #sleep 2

      @result = ClassicCarDbStructure.get_models(manufacturers)

      puts @result

      manufacturers.each do |result|
        next if result == nil || result == '' || result == ' ' || result.nil?
        # Write in Json file
        File.open("classic_car_db_jsons/#{result[:name]}.json", 'w') do |f|
          f.write result.to_json
        end
      end
    end
  end

  def self.get_edmunds_manufacturers
    doc         = Network.get_parsed_source(Url.edmunds_webpage)
    form_source = doc.css('form')

    manufacturer_values = form_source.css('select.hp-makes option')

    manufacturer_values.map do |value|
      next if value.text == 'Select make'
      #next unless value.text == 'Acura'

      manufacturer_title = get_manuf_title_edmunds(value)
      manufacturer_name  = get_manuf_name_edmunds(value)


      manufacturer_info = []
      manufacturer_info << { title: manufacturer_title,
                             name:  manufacturer_name }

      sleep 1

      @result = EdmundsStructure.get_models(manufacturer_info)

      #   puts @result
      #
      #   manufacturers.each do |result|
      #     next if result == nil || result == '' || result == ' ' || result.nil?
      #     # Write in Json file
      #     File.open("classic_car_db_jsons/#{result[:name]}.json", 'w') do |f|
      #       f.write result.to_json
      #     end
      #   end
    end
  end

  private

  def self.get_manuf_title_edmunds(value)
    value.text.strip
  end

  def self.get_manuf_name_edmunds(value)
    value.attr('value').strip
  end

  def self.extract_manufacturer_from_url(manufacturer_links)
    manufacturer_links = manufacturer_links.slice(0, (manufacturer_links.size-1)) # cut off last '/'
    index              = manufacturer_links.rindex('/') # find now the last '/'
    manufacturer_links = manufacturer_links.slice(index+1, manufacturer_links.size) # cut form last '/' till end
    manufacturer_links = manufacturer_links.gsub(/.asp/, '').strip
    manufacturer_links
  end

  def self.find_manufacturer_title(element)
    manufacturer_title = element.text.strip
    manufacturer_title
  end

  def self.find_manufacturer_name(element)
    manufacturer_name = element.text.downcase.gsub(/\//, '-').strip
    manufacturer_name = manufacturer_name.gsub(/\s/, '-').strip
    manufacturer_name = manufacturer_name.gsub(/\//, '-').strip
    manufacturer_name
  end

  def self.extract_manufacturer_title(element)
    manufacturer = element.text.strip
    manufacturer
  end

  def self.extract_manufacturer_name(element)
    manufacturer = element.text.downcase.gsub(/\s/, '-').gsub(/\//, '-').strip
    manufacturer
  end

  def self.clear_manufacturer_title(element)
    manufacturer_title = element.text.strip
    manufacturer_title = manufacturer_title.gsub(/\d{1,5}$/, '').strip
    manufacturer_title
  end

  def self.clear_manufacturer_name(element)
    manufacturer_name = element.text.strip
    manufacturer_name = manufacturer_name.gsub(/\d{1,5}$/, '').strip
    manufacturer_name = manufacturer_name.downcase
    manufacturer_name = manufacturer_name.gsub(/\s/, '-').strip
    manufacturer_name = manufacturer_name.gsub(/\./, '-').strip
    manufacturer_name = manufacturer_name.gsub(/-$/, '').strip
    manufacturer_name
  end

  def self.get_manufacturer_title(element)
    manufacturer_title = element.text.strip
    manufacturer_title
  end

  def self.get_manufacturer_name(element)
    manufacturer_name = element.text.strip
    manufacturer_name = manufacturer_name.gsub(/\./, '-').strip
    manufacturer_name = manufacturer_name.gsub(/-$/, '').strip
    manufacturer_name = manufacturer_name.gsub(/\)/, '').strip
    manufacturer_name = manufacturer_name.gsub(/\(/, '').strip
    manufacturer_name = manufacturer_name.gsub(/\s/, '-').strip
    manufacturer_name = manufacturer_name.downcase
    manufacturer_name
  end
end

# RootScraper.car_logos_manufacturers
#RootScraper.car_folio_manufacturers
#RootScraper.get_caricos_manufacturers
# RootScraper.conceptcarz_manufacturers
#RootScraper.get_parkers_information
# RootScraper.car_styling_manufacturers
#RootScraper.classic_car_db_manufacturers
#RootScraper.get_edmunds_manufacturers



