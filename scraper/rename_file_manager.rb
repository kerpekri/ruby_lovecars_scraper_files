#!/usr/bin/env ruby
# encoding: utf-8
require 'csv'

# NOT FINISHED

class RenameFileManager

  def self.start
    CSV.open('parkers_csv_file.csv', 'ab') do |writer|
      index = 0
      iterate_through_directory(writer, index)
    end
  end

  private

  def self.iterate_through_directory(writer, index)
    Dir.glob("parkers_files/*") do |root_directory|
      Dir.glob("#{root_directory}" + "/*") do |item|
        Dir.glob("#{item}" + "/*") do |folder|
          Dir.glob("#{folder}" + "/*") do |element|

            #index      += 1
            #image_name = create_image_name(element, index)

            #rename_file_name(image_name, element, index, writer)
          end
        end
      end
    end
  end

  def self.create_image_name(element, index)
    name = element.gsub(/parkers_files/, '')
    name = name.gsub(/\.jpg/, '')
    name = name.gsub(/\/\d{2}$/, '')
    name = name.gsub(/\/\d{1}$/, '')
    name = name.gsub(/\//, '_')
    name = name.gsub(/^_/, '').strip
    name = name + '_' + "#{index}"
    name
  end

  def self.rename_file_name(new_image_name, item, index, writer)
    dir  = get_correct_dir(index)
    path = dir + new_image_name + File.extname(item)

    File.rename(item, path)
    insert_into_csv_file(writer, path)
  end

  def self.get_correct_dir(index)
    case index
      when 0..999
        '1/'
      when 1000..1999
        '2/'
      when 2000..2999
        '3/'
      when 3000..3999
        '4/'
      when 4000..4999
        '5/'
      when 5000..5999
        '6/'
      when 6000..6999
        '6/'
      else
        '8/'
    end
  end

  def self.insert_into_csv_file(writer, image_path)
    writer << [image_path]
  end
end

RenameFileManager.start
