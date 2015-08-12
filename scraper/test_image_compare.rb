#todo on-hold.
require 'phashion'
require 'open-uri'

class ImageCompare
  def self.start

  end

  def self.start_logic(filename_1, filename_2)
    # compare all of them one by one
    img1 = Phashion::Image.new(filename_1)
    img2 = Phashion::Image.new(filename_2)

    xxx = img1.duplicate?(img2)

    puts xxx
  end

  def self.download_image(url)
    # pass array with images
    File.open(create_uniq_timestamp + '.jpg', 'wb') do |f|
      f.write(open(url).read)
    end
  end

  private

  def self.create_uniq_timestamp
    Time.now.to_s.gsub(' ', '').gsub('+', '').gsub('-', '').gsub(':', '') + rand(10..100).to_s
  end
end

ImageCompare.download_image('http://www.conceptcarz.com/images/Fiat/Fiat-Abarth-695-Biposto-image-2014-03.jpg')
# ImageCompare.start_logic('1_duplicate.jpg', '2_duplicate.jpg')
#ImageCompare.start_logic('1_duplicate.jpg', '4_normal.jpg')

# http://www.conceptcarz.com/images/Fiat/Fiat-Abarth-695-Biposto-image-2014-01.jpg - duplicates
# http://www.conceptcarz.com/images/Fiat/Fiat-Abarth-695-Biposto-image-2014-01-1600.jpg - duplicates

# http://www.conceptcarz.com/images/Fiat/Fiat-Abarth-695-Biposto-image-2014-02.jpg
# http://www.conceptcarz.com/images/Fiat/Fiat-Abarth-695-Biposto-image-2014-03.jpg
