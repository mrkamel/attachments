
require "aws-sdk"
require "mime-types"

module Attachments
  class S3MultipartUpload
    include MonitorMixin

    def initialize(s3_client, name, bucket, options, &block)
      super()

      @s3_client = s3_client
      @bucket = bucket
      @name = name

      @index = 0

      upload_id = s3_client.create_multipart_upload(options.merge(bucket: bucket, key: name)).to_h["upload_id"]

      begin
        block.call(self)
      rescue => e
        s3_client.abort_multipart_upload(bucket: bucket, key: name, upload_id: upload_id)

        raise e
      end

      s3_client.complete_multipart_upload(bucket: bucket, key: name, upload_id: upload_id)
    end

    def upload_part(data_or_io)
      index = synchronize { @index += 1 }

      @s3_client.upload_part(body: data_or_io, bucket: @bucket, key: @name, upload_id: @upload_id, part_number: index)
    end
  end

  class S3Driver
    attr_accessor :s3_client, :s3_resource

    def initialize(s3_client)
      self.s3_client = s3_client
      self.s3_resource = Aws::S3::Resource.new(:client => s3_client)
    end

    def store(name, data_or_io, bucket, options = {})
      opts = options.dup

      mime_type = MIME::Types.of(name).first

      opts[:content_type] ||= mime_type.content_type if mime_type
      opts[:content_type] ||= "application/octet-stream"

      opts[:body] = data_or_io

      s3_resource.bucket(bucket).object(name).put(opts)
    end 

    def store_multipart(name, bucket, options = {}, &block)
      opts = options.dup

      mime_type = MIME::Types.of(name).first

      opts[:content_type] ||= mime_type.content_type if mime_type
      opts[:content_type] ||= "application/octet-stream"

      S3MultipartUpload.new(s3_client, name, bucket, opts, &block)
    end

    def value(name, bucket)
      s3_resource.bucket(bucket).object(name).get.body.read.force_encoding(Encoding::BINARY)
    end 

    def delete(name, bucket)
      s3_resource.bucket(bucket).object(name).delete
    end 

    def exists?(name, bucket)
      s3_resource.bucket(bucket).object(name).exists?
    end 

    def temp_url(name, bucket, options = {})
      opts = options.dup
      opts[:expires_in] = opts.delete(:expires_in).to_i if opts.key?(:expires_in)

      method = opts.delete(:method) || :get

      s3_resource.bucket(bucket).object(name).presigned_url(method, opts)
    end
  end
end

