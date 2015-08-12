#!/usr/bin/env ruby
# encoding: utf-8
class ParkersImages
  def self.get_images(params, writer, image_elements)
    @db         = connect_to_database
    index       = 0
    @model_year = remove_specific_characters(params[:model_year])

    create_csv_file(writer, index, params, image_elements)
  end

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

  private

  def self.create_csv_file(writer, index, params, image_elements)
    manufacturer_id = find_manufacturer_id(params[:manufacturer_name])
    model_id        = find_model_id(manufacturer_id, params[:model_name])
    generation_id   = find_generation_id(model_id, @model_year)

    image_elements.each do |image|
      sleep 1

      if generation_id == 'NEW_GENERATION_ID'
        next
      else
        image_link = get_image_link(image)
        puts 'Start:'

        # skip broken links
        begin
          directory = get_directory(params[:manufacturer_name])

          full_path = "#{directory.first}/#{params[:manufacturer_name]}_#{params[:model_name]}_#{@model_year}_#{index}.jpg"
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
  end

  def self.get_directory(manufacturer_name)
    case manufacturer_name
      when 'honda' then
        '8'
      when 'hyundai' then
        '9'
      when 'infinity' then
        '10'
      when 'jaguar' then
        '11'
      when 'jeep' then
        '12'
      when 'kia' then
        '13'
      when 'lamborghini' then
        '14'
      when 'lexus' then
        '15'
      when 'lotus' then
        '16'
      when 'maserati' then
        '17'
      when 'mazda' then
        '18'
      when 'land-rover' then
        '19'
      when 'mclaren' then
        '20'
      when 'mercedes-benz' then
        '21'
      when 'mg-motor-uk' then
        '22'
      when 'mini' then
        '23'
      when 'mitsubishi' then
        '24'
      when 'morgan' then
        '25'
      when 'nissan' then
        '26'
      when 'perodua' then
        '27'
      when 'peugeot' then
        '28'
      when 'porsche' then
        '29'
      when 'proton' then
        '30'
      when 'renault' then
        '31'
      when 'rolls-royce' then
        '32'
      when 'seat' then
        '33'
      when 'skoda' then
        '34'
      when 'smart' then
        '35'
      when 'ssangyong' then
        '36'
      when 'subaru' then
        '37'
      when 'suzuki' then
        '38'
      when 'tesla' then
        '39'
      when 'toyota' then
        '40'
      when 'vauxhall' then
        '41'
      when 'volkswagen' then
        '42'
      when 'volvo' then
        '43'
      else
        '44'
    end
  end

  def self.remove_specific_characters(model_year)
    year_name = model_year.downcase.strip
    year_name = year_name.gsub(/\s/, '').strip
    year_name
  end

  def self.define_source
    'www.parkers.com'
  end

  def self.insert_into_csv_file(writer, generation_id, full_path, source)
    writer << [generation_id, full_path, source]
  end

  # def self.create_image_directory
  #   FileUtils::mkdir_p '1'
  # end

  def self.get_image_link(image)
    image.attr('href')
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
