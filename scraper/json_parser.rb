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

require_relative 'connections/network.rb'
require_relative 'website_structures/cleaners/cleaner_for_parkers.rb'
require_relative 'database_insert.rb'

class JsonParser

  def self.start
    Dir['carfolio_jsons/*.json'].each do |file|
      next if file == nil || file == '' || file == ' ' || file.nil?
      file_res = File.open(file, 'r').readlines().first
      result   = JSON.parse(file_res, symbolize_names: true)
      DatabaseInsert.fill_manufacturer_name(result)
    end
  end
end

Scraper.start
