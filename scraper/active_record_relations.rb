class Car < ActiveRecord::Base
  # has_many :cars_two, class: 'Car'
  self.table_name = 'car'
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

class CarImage < ActiveRecord::Base
  self.table_name = 'car_image'
  belongs_to :car
end
