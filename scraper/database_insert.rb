#!/usr/bin/env ruby
# encoding: utf-8
class Car < ActiveRecord::Base
  self.table_name = 'car'
  belongs_to :car_manufacturer
  has_many :car_body_types
  has_many :body_types, :through => :car_body_types
end

class CarClosure < ActiveRecord::Base
  self.table_name = 'car_closure'
end

class CarBodyType < ActiveRecord::Base
  self.table_name = 'car_body_type'
  belongs_to :body_type
  belongs_to :car
end

class BodyType < ActiveRecord::Base
  self.table_name = 'body_type'
  has_many :car_body_types
  has_many :cars, :through => :car_body_types
end

class CarManufacturer < ActiveRecord::Base
  self.table_name = 'car_manufacturer'
  has_many :cars
  validates :name, :presence => true
end

class CarSpec < ActiveRecord::Base
  self.table_name = 'car_spec'
  has_many :car_attributes
end

class CarAttribute < ActiveRecord::Base
  self.table_name = 'car_attribute'
  belongs_to :car_specs
end

class DatabaseInsert

  def self.fill_manufacturer_name(scraper_result)
    manufacturers = []
    #manufacturers << scraper_result
    setup_db_connection

    unless scraper_result.nil?
      scraper_result.each do |manufacturer|
        next if manufacturer[:name] == nil || manufacturer[:name] == '' || manufacturer[:name] == ' ' || manufacturer[:name].nil?

        db_manufacturer = CarManufacturer.find_by(name: manufacturer[:name])

        if db_manufacturer.nil?
          db_manufacturer        = CarManufacturer.new()
          db_manufacturer.name   = manufacturer[:name]
          db_manufacturer.title  = manufacturer[:title]
          db_manufacturer.source = 'www.carfolio.com'
          db_manufacturer.save!
        end
        fill_models(db_manufacturer, manufacturer)
      end
    end
  end

  private

  def self.fill_models(db_manufacturer, manufacturer)
    models = manufacturer[:models]

    unless models.nil?
      models.each do |model|
        next if model[:name] == nil || model[:name] == '' || model[:name] == ' ' || model[:name].nil?

        models = Car.select('car.title', 'car.name', 'car.id')
                     .where('car.title = ? OR car.name = ?', model[:title], model[:name])
                     .joins('INNER JOIN car_closure ON car_closure.descendant = car.id')
                     .joins('INNER JOIN car_manufacturer ON car_manufacturer.id = car.car_manufacturer_id')
                     .where('car_closure.ancestor = 1')
                     .where('car_closure.level = 1')
                     .where('car_manufacturer.name = (?)', db_manufacturer.name)
                     .where('car_manufacturer.id = (?)', db_manufacturer.id)

        if models.blank?
          db_models                     = Car.new()
          db_models.name                = model[:name]
          db_models.title               = model[:title]
          db_models.car_manufacturer_id = db_manufacturer[:id]
          db_models.source              = 'carfolio'
          db_models.source_url          = 'www.carfolio.com'
          db_models.save

          db_car_closure            = CarClosure.new()
          db_car_closure.ancestor   = db_models[:id]
          db_car_closure.descendant = db_models[:id]
          db_car_closure.level      = 0
          db_car_closure.save

          db_car_closure            = CarClosure.new()
          db_car_closure.ancestor   = 1
          db_car_closure.descendant = db_models[:id]
          db_car_closure.level      = 1
          db_car_closure.save
        end
        fill_body_types(db_models, db_car_closure, db_manufacturer, manufacturer, model, models)
      end
    end
  end

  def self.fill_body_types(db_models, db_car_closure, db_manufacturer, manufacturer, model, models)
    body_types = model[:body_types]
    body_types.each do |body_type|
      next if body_type == nil || body_type == '' || body_type == ' ' || body_type.nil?

      # Will not be used , just passing through one level!
      fill_years(body_type, db_models, db_car_closure, db_manufacturer, manufacturer, model, models)
    end
  end

  def self.fill_years(body_type, db_models, db_car_closure, db_manufacturer, manufacturer, model, models)
    years = body_type[:years]

    unless years.nil?
      years.each do |year|
        next if year[:year] == nil || year[:year] == '' || year[:year] == ' ' || year[:year].nil?

        years = Car.joins('INNER JOIN car_closure ON car_closure.descendant = car.id')
        years = years.where('car_closure.level = 1')
        years = years.where('car.title = (?)', year[:year])

        if db_models.nil?
          years = years.where('car_closure.ancestor = (?)', models.first.id)
        else
          years = years.where('car_closure.ancestor = (?)', db_models[:id])
        end

        if years.blank?
          db_model_year = Car.new({
                                      name:                year[:year],
                                      title:               year[:year].capitalize,
                                      car_manufacturer_id: db_manufacturer[:id],
                                      source:              'carfolio',
                                      source_url:          'www.carfolio.com'
                                  })
          db_model_year.save

          db_years_first            = CarClosure.new()
          db_years_first.ancestor   = db_model_year[:id]
          db_years_first.descendant = db_model_year[:id]
          db_years_first.level      = 0
          db_years_first.save

          db_years_second = CarClosure.new()

          if db_models.nil?
            db_years_second.ancestor = models.first.id
          else
            db_years_second.ancestor = db_models[:id]
          end

          db_years_second.descendant = db_model_year[:id]
          db_years_second.level      = 1
          db_years_second.save

          db_years_third            = CarClosure.new()
          db_years_third.ancestor   = 1
          db_years_third.descendant = db_model_year[:id]
          db_years_third.level      = 2
          db_years_third.save
        end
        fill_model_type(db_model_year, db_years_third, db_years_second, db_years_first, year, body_type, db_models, db_car_closure, db_manufacturer, manufacturer, model, models, years)
      end
    end
  end

  def self.fill_model_type(db_model_year, db_years_third, db_years_second, db_years_first, year, body_type, db_models, db_car_closure, db_manufacturer, manufacturer, model, models, years)
    model_versions = year[:versions]

    unless model_versions.nil?
      model_versions.each do |model_version|
        next if model_version[:model_type] == nil || model_version[:model_type] == '' || model_version[:model_type] == ' ' || model_version[:model_type].nil?

        model_versions = Car.select('id')
        model_versions = model_versions.joins('INNER JOIN car_closure ON car_closure.descendant = car.id')
        model_versions = model_versions.where('car_closure.level = 2')
        model_versions = model_versions.where('car.title = (?)', model_version[:model_type])

        if db_models.nil?
          model_versions = model_versions.where('car_closure.ancestor = (?)', models.first.id)
        else
          model_versions = model_versions.where('car_closure.ancestor = (?)', db_models[:id])
        end

        if model_versions.blank?
          db_model_type                     = Car.new()
          db_model_type.name                = model_version[:model_type]
          db_model_type.title               = model_version[:model_type].capitalize
          db_model_type.car_manufacturer_id = db_manufacturer[:id]
          db_model_type.source              = 'carfolio'
          db_model_type.source_url          = 'www.carfolio.com'
          db_model_type.save!

          db_model_type_first            = CarClosure.new()
          db_model_type_first.ancestor   = db_model_type[:id]
          db_model_type_first.descendant = db_model_type[:id]
          db_model_type_first.level      = 0
          db_model_type_first.save

          db_model_type_second          = CarClosure.new()
          db_model_type_second.ancestor =
              if db_model_year.nil?
                years.first.id
              else
                db_model_year[:id]
              end

          db_model_type_second.descendant = db_model_type[:id]
          db_model_type_second.level      = 1
          db_model_type_second.save

          db_model_type_third          = CarClosure.new()
          db_model_type_third.ancestor =
              if db_models.nil?
                models.first.id
              else
                db_models[:id]
              end

          db_model_type_third.descendant = db_model_type[:id]
          db_model_type_third.level      = 2
          db_model_type_third.save

          db_model_type_third            = CarClosure.new()
          db_model_type_third.ancestor   = 1
          db_model_type_third.descendant = db_model_type[:id]
          db_model_type_third.level      = 3
          db_model_type_third.save
        end
        fill_model_details(model_versions, model_version, db_model_type, db_model_year, db_years_third, db_years_second, db_years_first, year, body_type, db_models, db_car_closure, db_manufacturer, manufacturer, model)
        #fill_model_body_types(model_versions, model_version, db_model_type, db_model_year, db_years_third, db_years_second, db_years_first, year, body_type, db_models, db_car_closure, db_manufacturer, manufacturer, model)
      end
    end
  end

  def self.fill_model_details(model_versions, model_version, db_model_type, db_model_year, db_years_third, db_years_second, db_years_first, year, body_type, db_models, db_car_closure, db_manufacturer, manufacturer, model)
    model_details = model_version[:details]
    model_details.each do |model_detail|
      next if model_detail== nil || model_detail == '' || model_detail == ' ' || model_detail.nil?

      model_details = CarSpec.joins('INNER JOIN car_attribute ON car_attribute.id = car_spec.car_attribute_id')

      if db_model_type.nil?
        model_details = model_details.where('car_spec.car_id = (?)', model_versions.first.id)
      else
        model_details = model_details.where('car_spec.car_id = (?)', db_model_type[:id])
      end

      if model_details.blank?
        model_version[:details].each do |detail|
          next if detail[:name] == nil || detail[:name] == '' || detail[:name] == ' ' || detail[:name].nil?

          params = {
              car_id: (db_model_type.nil? ? model_versions.first.id : db_model_type[:id]),
              value:  detail[:value],
              source: 'carfolio'
          }
          begin
            #TODO - WTF? O.o
            db_model_specification                  = CarSpec.new(params)
            db_model_specification.car_attribute_id = 26 if detail[:name].downcase == 'production'
            db_model_specification.car_attribute_id = 5 if detail[:name].downcase == 'width'
            db_model_specification.car_attribute_id = 4 if detail[:name].downcase == 'length'
            db_model_specification.car_attribute_id = 6 if detail[:name].downcase == 'height'
            db_model_specification.car_attribute_id = 28 if detail[:name].downcase == 'weight'
            db_model_specification.car_attribute_id = 29 if detail[:name].downcase == 'fuel delivery'
            db_model_specification.car_attribute_id = 15 if detail[:name].downcase == 'transmission'
            db_model_specification.car_attribute_id = 1 if detail[:name].downcase == 'list price'
            db_model_specification.car_attribute_id = 13 if detail[:name].downcase == 'mpg'
            db_model_specification.car_attribute_id = 31 if detail[:name].downcase == 'insurance group'
            db_model_specification.car_attribute_id = 32 if detail[:name].downcase == 'euro emissions standard'
            db_model_specification.car_attribute_id = 33 if detail[:name].downcase == 'co2 emissions'
            db_model_specification.car_attribute_id = 30 if detail[:name].downcase == 'gears'
            db_model_specification.car_attribute_id = 34 if detail[:name].downcase == 'ved band'
            db_model_specification.car_attribute_id = 35 if detail[:name].downcase == 'engine size'
            db_model_specification.car_attribute_id = 36 if detail[:name].downcase == 'cylinders'
            db_model_specification.car_attribute_id = 37 if detail[:name].downcase == '0-60 mph'
            db_model_specification.car_attribute_id = 38 if detail[:name].downcase == 'top speed'
            db_model_specification.car_attribute_id = 9 if detail[:name].downcase == 'power output'
            db_model_specification.car_attribute_id = 9 if detail[:name].downcase == 'power'
            db_model_specification.car_attribute_id = 39 if detail[:name].downcase == 'valves'
            db_model_specification.car_attribute_id = 10 if detail[:name].downcase == 'torque'
            db_model_specification.car_attribute_id = 7 if detail[:name].downcase == 'wheelbase'
            db_model_specification.car_attribute_id = 19 if detail[:name].downcase == 'luggage capacity'
            db_model_specification.car_attribute_id = 14 if detail[:name].downcase == 'fuel capacity'
            db_model_specification.car_attribute_id = 18 if detail[:name].downcase == 'turning circle'
            db_model_specification.car_attribute_id = 40 if detail[:name].downcase == 'unbraked towing weight'
            db_model_specification.car_attribute_id = 41 if detail[:name].downcase == 'braked towing weight'
            db_model_specification.car_attribute_id = 21 if detail[:name].downcase == 'seating capacity'
            db_model_specification.car_attribute_id = 18 if detail[:name].downcase == 'turning circle'
            db_model_specification.car_attribute_id = 28 if detail[:name].downcase == 'weight'
            db_model_specification.car_attribute_id = 12 if detail[:name].downcase == 'mpg city'
            db_model_specification.car_attribute_id = 11 if detail[:name].downcase == 'mpg highway'
            db_model_specification.car_attribute_id = 17 if detail[:name].downcase == 'ground clearance'
            db_model_specification.car_attribute_id = 3 if detail[:name].downcase == 'drive type'
            db_model_specification.car_attribute_id = 20 if detail[:name].downcase == 'doors'
            db_model_specification.car_attribute_id = 4 if detail[:name].downcase == 'length'
            db_model_specification.car_attribute_id = 5 if detail[:name].downcase == 'width'
            db_model_specification.car_attribute_id = 6 if detail[:name].downcase == 'height'
            db_model_specification.car_attribute_id = 7 if detail[:name].downcase == 'wheelbase'
            db_model_specification.car_attribute_id = 45 if detail[:name].downcase == 'front brakes'
            db_model_specification.car_attribute_id = 46 if detail[:name].downcase == 'rear brakes'
            db_model_specification.car_attribute_id = 13 if detail[:name].downcase == 'combined mpg'
            db_model_specification.car_attribute_id = 19 if detail[:name].downcase == 'cargo volume'
            db_model_specification.car_attribute_id = 22 if detail[:name].downcase == 'front row headroom'
            db_model_specification.car_attribute_id = 24 if detail[:name].downcase == 'front row legroom'
            db_model_specification.car_attribute_id = 22 if detail[:name].downcase == 'front headroom'
            db_model_specification.car_attribute_id = 23 if detail[:name].downcase == 'rear headroom'
            db_model_specification.car_attribute_id = 24 if detail[:name].downcase == 'front legroom'
            db_model_specification.car_attribute_id = 25 if detail[:name].downcase == 'rear legroom'
            db_model_specification.car_attribute_id = 38 if detail[:name].downcase == 'top speed'
            db_model_specification.car_attribute_id = 14 if detail[:name].downcase == 'fuel capacity'
            db_model_specification.car_attribute_id = 51 if detail[:name].downcase == 'engine location'
            db_model_specification.car_attribute_id = 52 if detail[:name].downcase == 'body / chassis'
            db_model_specification.car_attribute_id = 53 if detail[:name].downcase == 'introduced at'
            db_model_specification.car_attribute_id = 54 if detail[:name].downcase == 'coefficient of drag'
            db_model_specification.car_attribute_id = 55 if detail[:name].downcase == 'interior volume'
            db_model_specification.car_attribute_id = 56 if detail[:name].downcase == 'front track'
            db_model_specification.car_attribute_id = 57 if detail[:name].downcase == 'rear track'
            db_model_specification.car_attribute_id = 58 if detail[:name].downcase == 'front hip room'
            db_model_specification.car_attribute_id = 59 if detail[:name].downcase == 'rear hip room'
            db_model_specification.car_attribute_id = 60 if detail[:name].downcase == 'front shoulder room'
            db_model_specification.car_attribute_id = 61 if detail[:name].downcase == 'rear shoulder room'
            db_model_specification.car_attribute_id = 62 if detail[:name].downcase == 'steering overall ratio'
            db_model_specification.car_attribute_id = 63 if detail[:name].downcase == 'turns lock to lock'
            db_model_specification.car_attribute_id = 64 if detail[:name].downcase == 'front brake size'
            db_model_specification.car_attribute_id = 65 if detail[:name].downcase == 'rear brake size'
            db_model_specification.car_attribute_id = 66 if detail[:name].downcase == '1st gear'
            db_model_specification.car_attribute_id = 67 if detail[:name].downcase == '2nd gear'
            db_model_specification.car_attribute_id = 68 if detail[:name].downcase == '3rd gear'
            db_model_specification.car_attribute_id = 69 if detail[:name].downcase == '4th gear'
            db_model_specification.car_attribute_id = 70 if detail[:name].downcase == '5th gear'
            db_model_specification.car_attribute_id = 71 if detail[:name].downcase == '6th gear'
            db_model_specification.car_attribute_id = 72 if detail[:name].downcase == '7th gear'
            db_model_specification.car_attribute_id = 73 if detail[:name].downcase == '8th gear'
            db_model_specification.car_attribute_id = 74 if detail[:name].downcase == 'towing capacity'
            db_model_specification.car_attribute_id = 75 if detail[:name].downcase == 'front overhang'
            db_model_specification.car_attribute_id = 76 if detail[:name].downcase == 'rear overhang'
            db_model_specification.car_attribute_id = 77 if detail[:name].downcase == 'rollover 2 wheel drive'
            db_model_specification.car_attribute_id = 78 if detail[:name].downcase == 'rollover 4 wheel drive'
            db_model_specification.car_attribute_id = 79 if detail[:name].downcase == 'tuner'
            db_model_specification.car_attribute_id = 80 if detail[:name].downcase == 'second row headroom'
            db_model_specification.car_attribute_id = 81 if detail[:name].downcase == 'third row headroom'
            db_model_specification.car_attribute_id = 82 if detail[:name].downcase == 'second row legroom'
            db_model_specification.car_attribute_id = 83 if detail[:name].downcase == 'third row legroom'
            db_model_specification.car_attribute_id = 84 if detail[:name].downcase == '1/4 mile'
            db_model_specification.car_attribute_id = 85 if detail[:name].downcase == 'mileage'
            db_model_specification.car_attribute_id = 86 if detail[:name].downcase == 'coach work'
            db_model_specification.car_attribute_id = 87 if detail[:name].downcase == 'voltage'
            db_model_specification.car_attribute_id = 88 if detail[:name].downcase == 'bed length'
            db_model_specification.car_attribute_id = 89 if detail[:name].downcase == 'body designer'
            db_model_specification.car_attribute_id = 90 if detail[:name].downcase == 'chassis number'
            db_model_specification.car_attribute_id = 91 if detail[:name].downcase == 'spare tire'
            db_model_specification.car_attribute_id = 92 if detail[:name].downcase == 'type'
            db_model_specification.car_attribute_id = 93 if detail[:name].downcase == 'frontal passenger'
            db_model_specification.car_attribute_id = 94 if detail[:name].downcase == 'standard payload'
            db_model_specification.car_attribute_id = 95 if detail[:name].downcase == 'front tire'
            db_model_specification.car_attribute_id = 95 if detail[:name].downcase == 'tyres front'
            db_model_specification.car_attribute_id = 95 if detail[:name].downcase == 'front wheel'
            db_model_specification.car_attribute_id = 96 if detail[:name].downcase == 'rear tire'
            db_model_specification.car_attribute_id = 96 if detail[:name].downcase == 'tyres rear'
            db_model_specification.car_attribute_id = 96 if detail[:name].downcase == 'rear wheel'
            db_model_specification.car_attribute_id = 97 if detail[:name].downcase == 'side rear passenger'
            db_model_specification.car_attribute_id = 98 if detail[:name].downcase == 'side driver'
            db_model_specification.car_attribute_id = 99 if detail[:name].downcase == 'frontal driver'
            db_model_specification.car_attribute_id = 100 if detail[:name].downcase == 'passenger volume'
            db_model_specification.car_attribute_id = 101 if detail[:name].downcase == 'original base price'
            db_model_specification.car_attribute_id = 102 if detail[:name].downcase == 'no. produced'
            db_model_specification.car_attribute_id = 103 if detail[:name].downcase == 'body maker'
            db_model_specification.car_attribute_id = 20 if detail[:name].downcase == 'no. doors'
            db_model_specification.car_attribute_id = 20 if detail[:name].downcase == 'no. doors'
            db_model_specification.car_attribute_id = 104 if detail[:name].downcase == 'passengers'
            db_model_specification.car_attribute_id = 105 if detail[:name].downcase == 'model number'
            db_model_specification.car_attribute_id = 106 if detail[:name].downcase == 'front tread'
            db_model_specification.car_attribute_id = 107 if detail[:name].downcase == 'rear tread'
            db_model_specification.car_attribute_id = 108 if detail[:name].downcase == 'displacement'
            db_model_specification.car_attribute_id = 109 if detail[:name].downcase == 'bore & stroke'
            db_model_specification.car_attribute_id = 43 if detail[:name].downcase == 'type'
            db_model_specification.car_attribute_id = 110 if detail[:name].downcase == 'compression ratio-std'
            db_model_specification.car_attribute_id = 111 if detail[:name].downcase == 'compression ratio-opt'
            db_model_specification.car_attribute_id = 112 if detail[:name].downcase == 'brake horsepower'
            db_model_specification.car_attribute_id = 113 if detail[:name].downcase == 'rated horsepower'
            db_model_specification.car_attribute_id = 114 if detail[:name].downcase == 'main bearings'
            db_model_specification.car_attribute_id = 115 if detail[:name].downcase == 'valve lifters'
            db_model_specification.car_attribute_id = 116 if detail[:name].downcase == 'block material'
            db_model_specification.car_attribute_id = 117 if detail[:name].downcase == 'engine numbers'
            db_model_specification.car_attribute_id = 118 if detail[:name].downcase == 'engine no. location'
            db_model_specification.car_attribute_id = 49 if detail[:name].downcase == 'lubrication'
            db_model_specification.car_attribute_id = 66 if detail[:name].downcase == '1st'
            db_model_specification.car_attribute_id = 67 if detail[:name].downcase == '2nd'
            db_model_specification.car_attribute_id = 68 if detail[:name].downcase == '3rd'
            db_model_specification.car_attribute_id = 69 if detail[:name].downcase == '4th'
            db_model_specification.car_attribute_id = 70 if detail[:name].downcase == '5th'
            db_model_specification.car_attribute_id = 20 if detail[:name].downcase == 'number of doors'
            db_model_specification.car_attribute_id = 106 if detail[:name].downcase == 'track/tread (front)'
            db_model_specification.car_attribute_id = 107 if detail[:name].downcase == 'track/tread (rear)'
            db_model_specification.car_attribute_id = 63 if detail[:name].downcase == 'turns lock-to-lock'
            db_model_specification.car_attribute_id = 109 if detail[:name].downcase == 'bore/stroke ratio'
            db_model_specification.car_attribute_id = 51 if detail[:name].downcase == 'engine position'
            db_model_specification.car_attribute_id = 119 if detail[:name].downcase == 'length:wheelbase ratio'
            db_model_specification.car_attribute_id = 120 if detail[:name].downcase == 'engine manufacturer'
            db_model_specification.car_attribute_id = 121 if detail[:name].downcase == 'engine code'
            db_model_specification.car_attribute_id = 122 if detail[:name].downcase == 'compression ratio'
            db_model_specification.car_attribute_id = 123 if detail[:name].downcase == 'aspiration'
            db_model_specification.car_attribute_id = 124 if detail[:name].downcase == 'final drive ratio'
            db_model_specification.car_attribute_id = 125 if detail[:name].downcase == 'front suspension'
            db_model_specification.car_attribute_id = 126 if detail[:name].downcase == 'rear suspension'
            db_model_specification.car_attribute_id = 127 if detail[:name].downcase == 'engine layout'
            db_model_specification.car_attribute_id = 128 if detail[:name].downcase == 'engine coolant'
            db_model_specification.car_attribute_id = 129 if detail[:name].downcase == 'intercooler'
            db_model_specification.car_attribute_id = 130 if detail[:name].downcase == 'catalytic converter'
            db_model_specification.car_attribute_id = 131 if detail[:name].downcase == 'brakes f/r'
            db_model_specification.car_attribute_id = 132 if detail[:name].downcase == 'top gear ratio'
            db_model_specification.car_attribute_id = 133 if detail[:name].downcase == 'rac rating'
            db_model_specification.car_attribute_id = 134 if detail[:name].downcase == 'crankshaft bearings'
            db_model_specification.car_attribute_id = 89 if detail[:name].downcase == 'designer'
            db_model_specification.car_attribute_id = 135 if detail[:name].downcase == 'torque split'
            db_model_specification.car_attribute_id = 102 if detail[:name].downcase == 'production total'
            db_model_specification.car_attribute_id = 54 if detail[:name].downcase == 'drag coefficient'
            db_model_specification.car_attribute_id = 136 if detail[:name].downcase == 'model family'
            db_model_specification.car_attribute_id = 137 if detail[:name].downcase == 'steering'
            db_model_specification.car_attribute_id = 95 if detail[:name].downcase == 'wheel size front'
            db_model_specification.car_attribute_id = 34 if detail[:name].downcase == 'ved band (uk)'
            db_model_specification.car_attribute_id = 96 if detail[:name].downcase == 'wheel size rear'
            db_model_specification.car_attribute_id = 33 if detail[:name].downcase == 'co2 effizienz (de)'
            db_model_specification.car_attribute_id = 138 if detail[:name].downcase == 'cda'
            db_model_specification.car_attribute_id = 105 if detail[:name].downcase == 'model code'
            db_model_specification.car_attribute_id = 139 if detail[:name].downcase == 'gearbox'
            db_model_specification.car_attribute_id = 52 if detail[:name].downcase == 'body type'
            db_model_specification.car_attribute_id = 29 if detail[:name].downcase == 'fuel system'
            db_model_specification.car_attribute_id = 140 if detail[:name].downcase == 'type'
            db_model_specification.car_attribute_id = 141 if detail[:name].downcase == 'make'
            db_model_specification.car_attribute_id = 15 if detail[:name].downcase == 'transmission type'
            db_model_specification.car_attribute_id = 142 if detail[:name].downcase == 'transmission drive'
            db_model_specification.car_attribute_id = 30 if detail[:name].downcase == 'no. of gears'
            db_model_specification.car_attribute_id = 143 if detail[:name].downcase == 'gear ratios'
            db_model_specification.car_attribute_id = 144 if detail[:name].downcase == 'reverse'
            db_model_specification.car_attribute_id = 145 if detail[:name].downcase == 'clutch type'
            db_model_specification.car_attribute_id = 146 if detail[:name].downcase == 'clutch size'
            db_model_specification.car_attribute_id = 147 if detail[:name].downcase == 'axle type'
            db_model_specification.car_attribute_id = 148 if detail[:name].downcase == 'differential'
            db_model_specification.car_attribute_id = 149 if detail[:name].downcase == 'differential ratio'
            db_model_specification.car_attribute_id = 150 if detail[:name].downcase == 'transmission front'
            db_model_specification.car_attribute_id = 151 if detail[:name].downcase == 'transmission rear'
            db_model_specification.car_attribute_id = 152 if detail[:name].downcase == 'steering gear'
            db_model_specification.car_attribute_id = 153 if detail[:name].downcase == 'service'
            db_model_specification.car_attribute_id = 154 if detail[:name].downcase == 'front size'
            db_model_specification.car_attribute_id = 155 if detail[:name].downcase == 'rear size'
            db_model_specification.car_attribute_id = 156 if detail[:name].downcase == 'emergency'
            db_model_specification.car_attribute_id = 157 if detail[:name].downcase == 'size'
            db_model_specification.car_attribute_id = 158 if detail[:name].downcase == 'exhaust system'
            db_model_specification.car_attribute_id = 159 if detail[:name].downcase == 'ignition system'
            db_model_specification.car_attribute_id = 160 if detail[:name].downcase == 'battery'
            db_model_specification.car_attribute_id = 161 if detail[:name].downcase == 'cooling system'
            db_model_specification.car_attribute_id = 162 if detail[:name].downcase == 'radiator'
            db_model_specification.car_attribute_id = 2 if detail[:name].downcase == 'fuel type'
            db_model_specification.car_attribute_id = 163 if detail[:name].downcase == 'wheel type'
            db_model_specification.car_attribute_id = 164 if detail[:name].downcase == 'wheel mfr'
            db_model_specification.car_attribute_id = 165 if detail[:name].downcase == 'wheel size'
            db_model_specification.car_attribute_id = 166 if detail[:name].downcase == 'tire type'
            db_model_specification.car_attribute_id = 167 if detail[:name].downcase == 'tire size'
            db_model_specification.car_attribute_id = 168 if detail[:name].downcase == 'spare location'
            db_model_specification.car_attribute_id = 169 if detail[:name].downcase == 'fuel'
            db_model_specification.car_attribute_id = 170 if detail[:name].downcase == 'oil'
            db_model_specification.car_attribute_id = 171 if detail[:name].downcase == 'transmission'
            db_model_specification.car_attribute_id = 172 if detail[:name].downcase == 'cooling system'
            db_model_specification.car_attribute_id = 173 if detail[:name].downcase == 'rear differential'
            db_model_specification.car_attribute_id = 174 if detail[:name].downcase == 'front differential'
            db_model_specification.car_attribute_id = 175 if detail[:name].downcase == 'transfer case'
            db_model_specification.car_attribute_id = 176 if detail[:name].downcase == 'classic rating'
            db_model_specification.car_attribute_id = 90 if detail[:name].downcase == 'vin/serial no.'
            db_model_specification.car_attribute_id = 177 if detail[:name].downcase == 'vin description'
            db_model_specification.car_attribute_id = 118 if detail[:name].downcase == 'vin location'
            db_model_specification.save
          rescue ActiveRecord::InvalidForeignKey
            File.open("test_case.json", 'a') do |f|
              f.write detail[:name].to_json
            end
          end
        end
      end
    end
  end

  def self.fill_model_body_types(model_versions, model_version, db_model_type, db_model_year, db_years_third, db_years_second, db_years_first, year, body_type, db_models, db_car_closure, db_manufacturer, manufacturer, model)
    body_types = model[:body_types]

    body_types.each do |body_type|
      body_types = BodyType.joins('INNER JOIN car_body_type ON car_body_type.body_type_id = body_type.id')

      if db_model_type.nil?
        body_types = body_types.where('car_body_type.car_id = (?)', model_versions.first.id)
      else
        body_types = body_types.where('car_body_type.car_id = (?)', model_versions[:id])
      end

      if body_types.blank?
        params        = {
            car_id:     (db_model_type.nil?) ? model_versions.first.id : db_model_type[:id],
            version_uk: 1,
            version_us: 0
        }
        db_body_types = CarBodyType.new(params)

        hash = {
            :convertible => 3,
            :suv         => 4,
            :coupe       => 5,
            :pickup      => 6,
            :hatchback   => 7,
            :van         => 8,
            :roadster    => 9,
            :truck       => 10,
            :limousine   => 60
        }

        # db_body_types.body_type_id = hash[body_type[:name].to_sym]
        # db_body_types.body_type_id = 1 if ['saloon', 'sedan'].include? body_type[:name]
        # db_body_types.body_type_id = 2 if ['estate', 'station wagon'].include? body_type[:name]
        # db_body_types.body_type_id = 61 if body_type[:name] == 'cabrio'
        # db_body_types.save
        # db_body_types.body_type_id ||= 62
        # still need more body_types!
      end
    end
  end

  def self.setup_db_connection
    ActiveRecord::Base.establish_connection(
        adapter:  'mysql2',
        host:     'localhost',
        database: '20may_lovecars',
        username: 'root',
        password: '',
        strict:   false
    )
    ActiveRecord::Base.logger = Logger.new(STDOUT)
  end
end
