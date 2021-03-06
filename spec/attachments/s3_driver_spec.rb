
require File.expand_path("../../spec_helper", __FILE__)

RSpec.describe Attachments::S3Driver do
  let(:driver) do
    Attachments::S3Driver.new(Aws::S3::Client.new(
      access_key_id: "access_key_id",
      secret_access_key: "secret_access_key",
      endpoint: "http://localhost:4569",
      region: "us-east-1"
    ))
  end

  it "should list objects" do
    begin
      driver.store("object1", "blob", "bucket")
      driver.store("object2", "blob", "bucket")
      driver.store("other", "blob", "bucket")

      expect(driver.list("bucket", prefix: "object").to_a).to eq(["object1", "object2"])
    ensure
      driver.delete("object1", "bucket")
      driver.delete("object2", "bucket")
      driver.delete("other", "bucket")
    end
  end

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

  it "should generate a temp_url" do
    expect(driver.temp_url("name", "bucket")).to be_url
  end
end

