#!/usr/bin/env ruby
# encoding: utf-8
require 'rubygems'
require 'mechanize'
require 'nokogiri'
require 'open-uri'
require 'csv'
require 'pg'
require 'active_record'
require 'active_support/all'
require 'logger'
require 'json'
require 'resolv-replace.rb'

require_relative '../active_record_relations.rb'


class CarLogosFullScraper

  def self.find_existing_id(title)
    connect_to_database

    source_name = title.downcase
    #db_id       = CarManufacturer.where('lower(title) LIKE ? OR lower(name) like ?', "%#{source_name}%", "%#{source_name}%")
    db_id       = CarManufacturer.where('title = ? OR name = ?', source_name, source_name)

    if db_id.blank?
      'NEW_ID'
    else
      db_id.first.id
    end
  end

  def self.get_logos
    CSV.open('csv_files/car-logos_full.csv', 'wb') do |writer|
      create_csv_file(writer)
    end
  end

  private

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

  def self.create_csv_file(writer)
    get_page_elements.each do |element|

      link = get_image_link(element)
      title = get_image_title(element)

      next if title.strip == 'Selden logo' ||
          title.strip == 'Lewis logo' ||
          title.strip == 'Savio logo' ||
          title.strip == 'Saxon logo' ||
          title.strip == 'James N Leitch logo' ||
          title.strip == 'Sbarro logo' ||
          title.strip == 'Schacht logo' ||
          title.strip == 'Scioneri logo' ||
          title.strip == 'Pin It' ||
          title.strip == '' ||
          title.strip == ' '

      next unless title.strip == 'Zebra logo'
      puts title

      name = remove_characters_from_title(title)

      unless title.nil?
        clean_title          = clear_image_title(title)
        title_with_extension = add_extension_to_title(clean_title)

        # skip broken links
        begin
          Mechanize.new.get(link).save "car_logos_images/full_scraper_images/#{clean_title}.jpg"
          insert_into_csv_file(writer, name, find_existing_id(name), title_with_extension, link)
        rescue SocketError
          next
        rescue Mechanize::ResponseCodeError
          next
        end
      end
    end
  end

  def self.add_extension_to_title(clean_title)
    clean_title + '.jpg'
  end

  def self.remove_characters_from_title(title)
    title = title.strip
    title = title.gsub(/\slogo/, '')
    title = title.gsub(/\sLogo/, '')
    title = title.gsub(/\sLogos/, '')
    title = title.gsub(/\sCar/, '')
    title = title.gsub(/\scar/, '')
    title
  end

  def self.clear_image_title(title)
    title = title.downcase.strip
    title = title.gsub(/\s-\s/, '-')
    title = title.gsub(/\s/, '-')
    title = title.gsub(/&/, '-')
    title = title.gsub(/-–-/, '-')
    title = 'car_logos-' + title
    title
  end


  def self.insert_into_csv_file(writer, title, existing_id, title_with_extension, link)
    writer << [existing_id, title, title_with_extension, link]
  end

  def self.get_image_title(element)
    title = element.attr('alt')

    if title.nil?
      title = element.attr('title').strip
    end
    title
  end

  def self.get_image_link(element)
    element.attr('src').strip
  end

  def self.parse_web_source
    get_parsed_source('http://car-logos.net/all-car-manufacturers-logos/')
  end

  def self.get_page_elements
    parse_web_source.search('div a img')
  end

  def self.get_parsed_source(url)
    agent                  = Mechanize.new
    agent.user_agent_alias = 'Mac Safari'
    page_source            = agent.get(url).body
    doc                    = Nokogiri.parse(page_source)
    doc
  end
end

CarLogosFullScraper.get_logos
