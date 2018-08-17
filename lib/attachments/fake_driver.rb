
module Attachments
  class FakeMultipartUpload
    include MonitorMixin

    def initialize(name, bucket, options, &block)
      super()

      @name = name
      @bucket = bucket

      block.call(self) if block_given?
    end

    def upload_part(data)
      synchronize do
        @data ||= ""
        @data << data
      end

      true
    end

    def data
      synchronize do
        @data
      end
    end

    def abort_upload; end
    def complete_upload; end
  end

  class FakeDriver
    class ItemNotFound < StandardError; end

    def list(bucket, prefix: nil)
      return enum_for(:list, bucket, prefix: prefix) unless block_given?

      objects(bucket).each do |key, _|
        yield key if prefix.nil? || key.start_with?(prefix)
      end
    end

    def store(name, data_or_io, bucket, options = {})
      objects(bucket)[name] = data_or_io.respond_to?(:read) ? data_or_io.read : data_or_io
    end 

    def store_multipart(name, bucket, options = {}, &block)
      objects(bucket)[name] = FakeMultipartUpload.new(name, bucket, options, &block).data
    end

    def exists?(name, bucket)
      objects(bucket).key?(name)
    end 

    def delete(name, bucket)
      objects(bucket).delete(name)
    end 

    def value(name, bucket)
      raise(ItemNotFound) unless objects(bucket).key?(name)

      objects(bucket)[name]
    end 

    def temp_url(name, bucket, options = {})
      "https://example.com/#{bucket}/#{name}?signature=signature&expires=expires"
    end

    def flush
      @objects = {}
    end 

    private

    def objects(bucket)
      @objects ||= {}
      @objects[bucket] ||= {}
    end 
  end 
end

