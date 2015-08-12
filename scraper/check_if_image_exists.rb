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
require 'json'
require 'csv'

class ExistsImageManager
  def self.start_parser
    parse_csv_file
  end

  def self.parse_csv_file
    CSV.foreach(File.path("full_list.csv")) do |col|
      check_if_file_exists(col)
    end
  end

  def self.check_if_file_exists(col)
    puts col[1] + '_' + "#{File.file?(col[1])}"
  end
end

ExistsImageManager.start_parser
