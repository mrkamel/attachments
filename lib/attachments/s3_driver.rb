
module Attachments
  class S3Driver
    attr_accessor :s3

    def initialize(s3)
      self.s3 = s3
    end

    def store(name, data_or_io, bucket, options = {})
      warn "[WARN] option :access is deprecated in favor of :acl" if options.key?(:access)

      opts = options.dup
      opts[:acl] = opts.delete(:access) if opts.key?(:access)

      s3.buckets[bucket].objects[name].write(data_or_io, opts)
    end 

    def value(name, bucket)
      s3.buckets[bucket].objects[name].read
    end 

    def delete(name, bucket)
      s3.buckets[bucket].objects[name].delete
    end 

    def exists?(name, bucket)
      s3.buckets[bucket].objects[name].exists?
    end 

    def temp_url(name, bucket, options = {})
      opts = options.dup
      opts[:expires] = opts.delete(:expires_in).to_i if opts.key?(:expires_in)

      method = opts.delete(:method) || :get

      s3.buckets[bucket].objects[name].url_for(method, opts)
    end
  end
end

