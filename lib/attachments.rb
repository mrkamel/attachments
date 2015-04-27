
require "attachments/version"
require "attachments/interpolation"

module Attachments
  class UnknownAttachment < StandardError; end
  class NoSuchVersion < StandardError; end
  class InterpolationError < StandardError; end

  def self.default_options
    @default_options ||= { :protocol => "http" }
  end

  class Attachment
    class Version
      attr_accessor :attachment, :name, :options

      def initialize(attachment, name, options)
        self.attachment = attachment
        self.name = name
        self.options = options
      end

      def url
        if option(:url_prefix)
          "#{interpolate option(:protocol)}://#{interpolate option(:host)}/#{interpolate option(:url_prefix)}/#{path}"
        else
          "#{interpolate option(:protocol)}://#{interpolate option(:host)}/#{path}"
        end
      end

      def path
        interpolate option(:path)
      end

      def container
        interpolate option(:container) || option(:bucket)
      end

      alias_method :bucket, :container

      def temp_url(opts = {})
        option(:driver).temp_url(path, container, opts)
      end

      def value
        option(:driver).value(path, container)
      end

      def store(data_or_io, opts = {})
        option(:driver).store(path, data_or_io, container, opts)
      end

      def delete
        option(:driver).delete(path, container)
      end

      def exists?
        option(:driver).exists?(path, container)
      end

      def inspect
        to_s
      end

      def object
        attachment.object
      end

      private

      def option(option_name)
        return attachment.options[:versions][name][option_name] if attachment.options[:versions][name].key?(option_name)
        return options[option_name] if options.key?(option_name)
        return attachment.options[option_name] if attachment.options.key?(option_name)

        Attachments.default_options[option_name]
      end

      def interpolate(str)
        raise(InterpolationError) unless str.is_a?(String)

        str.gsub(/:[a-zA-Z0-9_]+/) do |name|
          Interpolation.new(self).send(name.gsub(/^:/, ""))
        end
      end
    end

    attr_accessor :object, :options

    def initialize(object, options)
      self.object = object
      self.options = options
    end

    def version(name, opts = {})
      raise(NoSuchVersion, "No such version: #{name}") unless options[:versions][name]

      Version.new self, name, opts
    end

    def versions
      options[:versions].collect { |name, _| version name }
    end

    def inspect
      to_s
    end
  end

  def self.included(base)
    base.class_attribute :attachments
    base.attachments = {}

    base.extend ClassMethods
  end

  def attachment(name)
    definition = self.class.attachments[name]

    raise(UnknownAttachment) unless definition

    Attachment.new self, definition
  end

  module ClassMethods
    def attachment(name, options = {})
      self.attachments = attachments.merge(name => options)

      define_method name do |version = nil, options = {}|
        return instance_variable_get("@#{name}") if version.nil?

        attachment(name).version(version, options)
      end

      define_method "#{name}=" do |value|
        instance_variable_set "@#{name}", value
      end
    end
  end
end

