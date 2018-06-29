
require File.expand_path("../../spec_helper", __FILE__)

RSpec.describe Attachments::FileDriver do
  let(:driver) { Attachments::FileDriver.new("/tmp/attachments") }

  it "should store a blob" do
    begin
      driver.store("name", "blob", "bucket")

      expect(driver.exists?("name", "bucket")).to be(true)
      expect(driver.value("name", "bucket")).to eq("blob")
    ensure
      driver.delete("name", "bucket")
    end
  end

  it "should store a blob via multipart upload" do
    begin
      driver.store_multipart("name", "bucket") do |upload|
        upload.upload_part("chunk1")
        upload.upload_part("chunk2")
      end

      expect(driver.exists?("name", "bucket")).to be(true)
      expect(driver.value("name", "bucket")).to eq("chunk1chunk2")
    ensure
      driver.delete("name", "bucket")
    end
  end

  it "should delete a blob" do
    begin
      driver.store("name", "blob", "bucket")
      expect(driver.exists?("name", "bucket")).to be(true)

      driver.delete("name", "bucket")
      expect(driver.exists?("name", "bucket")).to be(false)
    ensure
      driver.delete("name", "bucket")
    end
  end
end

