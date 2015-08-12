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

require_relative '../../lovecars_scraper/scraper/connections/network.rb'
require_relative '../scraper/active_record_relations.rb'

class CarTypeScraper

  def self.get_car_type_manufacturers
    doc                   = Network.get_parsed_source('http://cartype.com/list/1/companies')
    manufacturer_elements = doc.css('td.name a')

    manufacturer_elements.map do |manufacturer_element|
      sleep 1
      manufacturer_title = find_manufacturer_title(manufacturer_element)
      manufacturer_name  = find_manufacturer_name(manufacturer_element)
      link               = get_logo_link(manufacturer_element)

      #next unless manufacturer_title == 'AC'

      CSV.open('car_type_logos.csv', 'ab') do |writer|
        get_logos(writer, create_manufacturer_hash(manufacturer_title, manufacturer_name, link))
      end
    end
  end

  def self.get_logos(writer, manufacturer_info)

    doc           = Network.get_parsed_source(manufacturer_info[:link])
    logo_elements = doc.css('div.logo_pic a')
    index         = 0

    logo_elements.each do |logo|
      sleep 2
      image_link = get_logo_href_element(logo)
      image_type = find_file_extension(logo)
      image_name = create_image_name(manufacturer_info[:manufacturer_name], index, image_type)

      # skip broken links
      begin
        Mechanize.new.get(image_link).save image_name
        index += 1

        insert_into_csv_file(writer,
                             find_existing_id(manufacturer_info[:manufacturer_name]),
                             manufacturer_info[:manufacturer_title],
                             manufacturer_info[:manufacturer_name],
                             image_name,
                             image_link)
      rescue SocketError
        next
      rescue Mechanize::ResponseCodeError
        next
      end
    end
  end

  private

  def self.find_file_extension(element)
    href = element.attr('href')

    if href.include? '.png'
      '.png'
    elsif href.include? '.jpg'
      '.jpg'
    elsif href.include? '.gif'
      '.gif'
    elsif href.include? '.jpeg'
      '.jpeg'
    else
      'NEW_EXTENSION'
    end
  end

  def self.connect_to_database
    ActiveRecord::Base.establish_connection(
        adapter:  'postgresql',
        host:     'localhost',
        database: 'postgres_lovecars',
        username: 'postgres',
        password: 'postgres'
    )
    ActiveRecord::Base.logger = Logger.new(STDOUT)
  end

  def self.find_existing_id(name)
    connect_to_database

    puts "NAME:::#{name}"
    source_name = name
    db_id       = CarManufacturer.where('title = ? OR name = ?', source_name, source_name)

    if db_id.blank?
      'NEW_ID'
    else
      db_id.first.id
    end
  end

  def self.define_source
    'cartype.com'
  end

  def self.insert_into_csv_file(writer, manufacturer_id, title, name, image_name, image_link)
    writer << [manufacturer_id, title, name, image_name, image_link, define_source]
  end

  def self.create_image_name(name, index, image_type)
    "car_type_images/#{name}"+'_'+"#{index}"+"#{image_type}"
  end

  def self.get_logo_href_element(logo)
    'http://cartype.com' + logo.attr('href')
  end

  def self.create_manufacturer_hash(title, name, link)
    {
        manufacturer_title: title,
        manufacturer_name:  name,
        link:               link
    }
  end

  def self.find_manufacturer_title(element)
    element.text.strip
  end

  def self.find_manufacturer_name(element)
    name = element.text.downcase.strip
    name = name.gsub(/\(/, '').strip
    name = name.gsub(/\s-\s/, '-').strip
    name = name.gsub(/\)/, '').strip
    name = name.gsub(/\s/, '-')
    name = name.gsub(/\./, '-')
    name = name.gsub(/-&-/, '-').strip
    name = name.gsub(/-$/, '').strip
    name = name.gsub(/--/, '-')
    name = name.gsub(/---/, '-').strip
    name
  end

  def self.get_logo_link(element)
    link = element.attr('href').strip
    link = link.gsub(/\s/, '_').strip
    link = 'http://cartype.com' + link
    link
  end
end

CarTypeScraper.get_car_type_manufacturers
