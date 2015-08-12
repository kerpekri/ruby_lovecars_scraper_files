#!/usr/bin/env ruby
# encoding: utf-8
class GetCarStylingImages
  def self.get_images(params, writer, image_elements)
    @db         = connect_to_database
    index       = 0
    @model_year = remove_specific_characters(params[:model_year])
    directory   = create_image_directory(@model_year, params)

    create_csv_file(writer, index, directory, params, image_elements)
  end

  private

  def self.find_manufacturer_id(manufacturer_name)
    @db
    CarManufacturer.where(name: manufacturer_name).first.id
  end

  def self.find_model_id(manufacturer_id, model_name)
    @db
    id = Car.select('car.id')
             .joins('INNER JOIN car_closure ON car_closure.descendant = car.id')
             .where('car_closure.ancestor = 1')
             .where('car_closure.level = 1')
             .where('car.car_manufacturer_id = (?)', manufacturer_id)
             .where('car.name = (?)', model_name)

    if id.blank?
      0
    else
      id.first.id
    end
  end

  def self.find_generation_id(model_id, generation_name)
    @db
    id = Car.select('car.id')
             .joins('INNER JOIN car_closure ON car_closure.descendant = car.id')
             .where('car_closure.ancestor = (?)', model_id)
             .where('car.name = (?)', generation_name)
             .where('car_closure.level = 1')

    if id.blank?
      'NEW_GENERATION_ID'
    else
      id.first.id
    end
  end

  def self.create_csv_file(writer, index, directory, params, image_elements)
    manufacturer_id = find_manufacturer_id(params[:manufacturer_name])
    model_id        = find_model_id(manufacturer_id, params[:model_name])
    generation_id   = find_generation_id(model_id, @model_year)

    image_elements.each do |image|
      next if image.attr('src') == 'images/izoom.gif'
      sleep 2

      image_link = get_image_link(image)
      puts 'Start:'

      # skip broken links
      begin

        full_path = "#{directory.first}/#{index}.jpg"
        index     += 1

        Mechanize.new.get(image_link).save "#{full_path}"
        insert_into_csv_file(writer, generation_id, full_path, define_source)
      rescue SocketError
        next
      rescue Mechanize::ResponseCodeError
        next
      end
      puts ':eND'
    end
  end

  def self.remove_specific_characters(model_year)
    year_name = model_year.downcase.strip
    year_name = year_name.gsub(/\s/, '').strip
    year_name
  end

  def self.define_source
    'www.carstyling.ru'
  end

  def self.insert_into_csv_file(writer, generation_id, full_path, source)
    writer << [generation_id, full_path, source]
  end

  def self.create_image_directory(model_year, params)
    FileUtils::mkdir_p "car_styling_files/#{params[:manufacturer_name]}/#{params[:model_name]}/#{model_year}"
  end

  def self.get_image_link(image)
    'http://www.carstyling.ru/' + image.attr('src')
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
end
