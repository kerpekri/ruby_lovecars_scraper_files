#todo in progress proxy switch!
#!/usr/bin/env ruby
# encoding: utf-8
require 'rubygems'
require 'mechanize'
require 'open-uri'
require 'pry'
require 'active_record'
require 'active_support/all'
require 'logger'
require 'json'
require 'net/telnet'
require 'socksify'
require 'nokogiri'

require_relative 'website_structures/parkers_structure.rb'
require_relative 'website_structures/conceptcarz_structure.rb'
require_relative 'website_structures/carfolio_structure.rb'
require_relative 'website_structures/car_logos_structure.rb'
require_relative 'website_structures/caricos_structure.rb'
require_relative 'website_structures/car_styling_structure.rb'
require_relative 'website_structures/classic_car_db_structure.rb'
#require_relative 'connections/network.rb'
require_relative 'website_structures/cleaners/cleaner_for_parkers.rb'
#require_relative 'connections/url.rb'
# require_relative 'database.rb'


require_relative 'website_structures/carfolio_structure.rb'

class Scraper
#   Switch to get random ip address!
  def self.test_proxy_switch

    doc                 = get_parsed_source('http://www.carfolio.com/specifications/')
    manufacturer_fields = doc.css('li.m a.man')

    manufacturer_fields.map do |manufacturer_field|
      manufacturer_name = manufacturer_field.css('strong').text.strip.gsub(/\s/, '-').strip
      manufacturer_link = manufacturer_field.attr('href').strip

      manufacturers = []
      manufacturers << { title: manufacturer_name.gsub(/-/, ' ').strip, name: manufacturer_name.downcase.strip, url: manufacturer_link }

      sleep 1

      @result = CarFolioStructure.get_models(manufacturers)

      puts @result.to_json

      # @result.each do |result|
      #   next unless result != nil
      #   puts result[:name]
      #   # Write in Json file
      #   File.open("carfolio_jsons/#{result[:name]}.json", 'w') do |f|
      #     f.write result.to_json
      #   end
      # end
    end

    #RootScraper.car_folio_manufacturers


  end

  private

  def self.get_parsed_source(url)

    original_ip = Mechanize.new.get("http://bot.whatismyipaddress.com").content
    puts "original IP is : #{original_ip}"

# socksify will forward traffic to Tor so you dont need to set a proxy for Mechanize from there
    TCPSocket::socks_server = "127.0.0.1"
    TCPSocket::socks_port   = "50001"
    tor_port                = 9051

    1.times do
      #Switch IP
      localhost = Net::Telnet::new("Host" => "localhost", "Port" => "#{tor_port}", "Timeout" => 10, "Prompt" => /250 OK\n/)
      localhost.cmd('AUTHENTICATE ""') { |c| throw "Cannot authenticate to Tor" if c != "250 OK\n" }
      localhost.cmd('signal NEWNYM') { |c| throw "Cannot switch Tor to new route" if c != "250 OK\n" }
      localhost.close
      sleep 1
      new_ip = Mechanize.new.get("http://bot.whatismyipaddress.com").content
      puts "new IP is #{new_ip}"
    end

    agent                  = Mechanize.new
    agent.user_agent_alias = 'Mac Safari'
    page_source            = agent.get(url).body
    doc                    = Nokogiri.parse(page_source)
    doc
  end
end

#Scraper.second_half_start
Scraper.test_proxy_switch
# tor --CookieAuthentication 0 --HashedControlPassword "" --ControlPort 9051 --SocksPort 50001

