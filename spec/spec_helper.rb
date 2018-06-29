
require File.expand_path("../../lib/attachments", __FILE__)

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

