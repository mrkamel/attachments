
module Attachments
  class FakeMultipartUpload
    include MonitorMixin

    def initialize(name, container, options, &block)
      super()

      @name = name
      @container = container

      block.call(self)
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
  end

  class FakeDriver
    class ItemNotFound < StandardError; end

    def store(name, data_or_io, container, options = {})
      objects(container)[name] = data_or_io.respond_to?(:read) ? data_or_io.read : data_or_io
    end 

    def store_multipart(name, container, options = {}, &block)
      objects(container)[name] = FakeMultipartUpload.new(name, container, options, &block).data
    end

    def exists?(name, container)
      objects(container).key?(name)
    end 

    def delete(name, container)
      objects(container).delete(name)
    end 

    def value(name, container)
      raise(ItemNotFound) unless objects(container).key?(name)

      objects(container)[name]
    end 

    def temp_url(name, container, options = {})
      "https://example.com/#{container}/#{name}?signature=signature&expires=expires"
    end

    def flush
      @objects = {}
    end 

    private

    def objects(container)
      @objects ||= {}
      @objects[container] ||= {}
    end 
  end 
end

