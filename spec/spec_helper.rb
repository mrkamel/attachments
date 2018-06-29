
require File.expand_path("../../lib/attachments", __FILE__)

require "attachments/file_driver"
require "attachments/fake_driver"
require "attachments/s3_driver"

class Product
  include Attachments

  attr_accessor :id

  def initialize(attributes = {})
    attributes.each do |key, value|
      self.send("#{key}=", value)
    end
  end

  attachment :image, host: ":subdomain.example.com", path_prefix: ":bucket", bucket: "images", driver: Attachments::FileDriver.new("/tmp/attachments"), versions: {
    thumbnail: { path: "products/:id/thumbnail.jpg" },
    original: { path: "products/:id/original.jpg" }
  }

  def subdomain
    "images"
  end
end

RSpec::Matchers.define :be_url do |expected|
  match do |actual|
    URI.parse(actual) rescue false
  end
end
