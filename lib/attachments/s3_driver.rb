
require "aws-sdk-s3"
require "mime-types"

module Attachments
  class S3MultipartUpload
    include MonitorMixin

    def initialize(s3_client, name, bucket, options, &block)
      super()

      @s3_client = s3_client
      @bucket = bucket
      @name = name

      @parts = []

      @upload_id = @s3_client.create_multipart_upload(options.merge(bucket: bucket, key: name)).to_h[:upload_id]

      if block_given?
        begin
          block.call(self)
        rescue => e
          abort_upload

          raise e
        end

        complete_upload
      end
    end

    def upload_part(data)
      index = synchronize do
        part_number = @parts.size + 1

        @parts << { part_number: part_number, etag: "\"#{Digest::MD5.hexdigest(data)}\"" }

        part_number
      end

      @s3_client.upload_part(body: data, bucket: @bucket, key: @name, upload_id: @upload_id, part_number: index)
    end

    def abort_upload
      @s3_client.abort_multipart_upload(bucket: @bucket, key: @name, upload_id: @upload_id)
    end

    def complete_upload
      @s3_client.complete_multipart_upload(bucket: @bucket, key: @name, upload_id: @upload_id, multipart_upload: { parts: @parts })
    end
  end

  class S3Driver
    attr_accessor :s3_client, :s3_resource

    def initialize(s3_client)
      self.s3_client = s3_client
      self.s3_resource = Aws::S3::Resource.new(client: s3_client)
    end

    def list(bucket, prefix: nil)
      return enum_for(:list, bucket, prefix: prefix) unless block_given?

      options = {}
      options[:prefix] = prefix if prefix

      s3_resource.bucket(bucket).objects(options).each do |object|
        yield object.key
      end
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

