
module Attachments
  class Interpolation
    attr_accessor :version

    def initialize(version)
      self.version = version
    end

    def container
      version.container
    end

    alias_method :bucket, :container

    def method_missing(name, *args, &block)
      version.object.send name
    end

    def respond_to?(name, *args)
      super(name, *args) || version.object.respond_to?(name, *args)
    end
  end
end

