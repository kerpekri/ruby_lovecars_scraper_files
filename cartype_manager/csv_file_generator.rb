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

class CsvFileGenerator

  def self.create_csv_file
    CSV.open('junk.csv', 'ab') do |writer|
      iterate_through_directory(writer)
    end
  end

  private

  def self.iterate_through_directory(writer)
    index = 0

    Dir.foreach('car_type_images') do |item|
      next if item == '.' || item == '..'
      puts item
      index += 1


      # insert_into_csv_file(writer,
      #                      find_existing_id(manufacturer_info[:manufacturer_name]),
      #                      manufacturer_info[:manufacturer_title],
      #                      manufacturer_info[:manufacturer_name],
      #                      image_name,
      #                      image_link)


    end
  end

  def self.insert_into_csv_file(writer, manufacturer_id, title, name, image_name, image_link)
    writer << [manufacturer_id, title, name, image_name, image_link, define_source]
  end
end

CsvFileGenerator.create_csv_file
