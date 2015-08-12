#!/usr/bin/env ruby
# encoding: utf-8
class CleanerForParkers
  #For Parkers website

  def self.clean_generation_links(generation_links)
    valid_links = []
    generation_links = generation_links.map { |a| a.attr('href').to_s }
    generation_links.each do |link|
      valid_links << link if link.include?('-reviews/')
    end
    valid_links.uniq
  end

  def self.clean_empty_links(years)
    valid_years = []

    years.each do |year|
      conditions = [
          year[:link] == '#',
          year[:link] == '',
          year[:year].gsub!(/on/, '- Present'),
          year[:year].gsub!(/to/, '-')
      ]
      valid_years << year unless conditions.include? true
    end

    valid_years.delete(nil)
    valid_years
  end

  def self.clean_details(details)
    new_array = []
    details.each do |value|
      hash_pair = {}
      value.map do |key, value|
        hash_pair[key] = value.strip.downcase
        # .gsub(/\s/, '_')
      end
      new_array << hash_pair
    end
    new_array
  end
end

private

def self.extract_manufacturer_from_url(url)
  url = url.slice(0, (url.size-1)) # cut off last '/'
  index = url.rindex('/') # find now the last '/'
  url = url.slice(index+1, url.size) # cut form last '/' till end
  # url = url.gsub(/-/, ' ')
  url
end
