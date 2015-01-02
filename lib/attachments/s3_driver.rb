
module Attachments
  class S3Driver
    def store(name, data_or_io, bucket, options = {})
      AWS::S3::S3Object.store name, data_or_io, bucket, options
    end 

    def value(name, bucket)
      AWS::S3::S3Object.value name, bucket
    end 

    def delete(name, bucket)
      AWS::S3::S3Object.delete name, bucket
    end 

    def exists?(name, bucket)
      AWS::S3::S3Object.exists? name, bucket
    end 

    def temp_url(name, bucket, options = {})
      AWS::S3::S3Object.url_for name, bucket, options
    end
  end
end

