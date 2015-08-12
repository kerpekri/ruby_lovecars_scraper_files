#!/usr/bin/env ruby
# encoding: utf-8
class DatabaseManager
  def self.find_manufacturer_id(manufacturer_name)
    connect_to_database
    CarManufacturer.where(name: manufacturer_name).first.id
  end

  def self.find_model_id(manufacturer_id, model_name)
    connect_to_database
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
    connect_to_database
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
