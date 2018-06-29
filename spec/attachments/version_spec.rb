
require File.expand_path("../../spec_helper", __FILE__)

RSpec.describe Attachments::Attachment::Version do
  it "should interpolate the host, path_prefix and path" do
    expect(Product.new(id: 1).image(:thumbnail).url).to eq("http://images.example.com/images/products/1/thumbnail.jpg")
  end
  
  it "should know the path without prefix" do
    expect(Product.new(id: 1).image(:thumbnail).path_without_prefix).to eq("products/1/thumbnail.jpg")
  end

  it "should know the bucket" do
    expect(Product.new(id: 1).image(:thumbnail).bucket).to eq("images")
  end

  it "should store a blob" do
    product = Product.new(id: 1)

    begin
      product.image(:thumbnail).store("blob")

      expect(product.image(:thumbnail).exists?).to be(true)
      expect(product.image(:thumbnail).value).to eq("blob")
    ensure
      product.image(:thumbnail).delete
    end
  end

  it "should support multipart uploads" do
    product = Product.new(id: 1)

    begin
      product.image(:thumbnail).store_multipart do |upload|
        upload.upload_part("chunk1")
        upload.upload_part("chunk2")
      end

      expect(product.image(:thumbnail).exists?).to be(true)
      expect(product.image(:thumbnail).value).to eq("chunk1chunk2")
    ensure
      product.image(:thumbnail).delete
    end
  end
end

