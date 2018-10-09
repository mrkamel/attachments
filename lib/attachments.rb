
require "attachments/version"
require "attachments/interpolation"
require "active_support/all"

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
        "#{interpolate option(:protocol)}://#{interpolate option(:host)}/#{interpolate(option(:url_prefix)).to_s + "/" if option(:url_prefix)}#{path}#{interpolate(option(:url_suffix)) if option(:url_suffix)}"
      end

      def path
        "#{interpolate(option(:path_prefix)) + "/" if option(:path_prefix)}#{path_without_prefix}"
      end

      def path_without_prefix
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

      def store_multipart(opts = {}, &block)
        option(:driver).store_multipart(path, container, opts, &block)
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

      def method_missing(method_name, *args, &block)
        return attachment.options[:versions][name][method_name.to_sym] if attachment.options[:versions][name].key?(method_name.to_sym)

        super
      end

      def respond_to_missing?(method_name, *args)
        attachment.options[:versions][name].key?(method_name.to_sym)
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

        str.gsub(/(?<!\\):[a-zA-Z][a-zA-Z0-9_]*/) do |attribute_name|
          Interpolation.new(self).send(attribute_name.gsub(/^:/, ""))
        end
      end
    end

    attr_accessor :object, :name, :options

    def initialize(object, name, options)
      self.object = object
      self.name = name
      self.options = options
    end

    def version(version_name, opts = {})
      raise(NoSuchVersion, "No such version: #{version_name}") unless options[:versions][version_name]

      Version.new self, version_name, opts
    end

    def versions
      options[:versions].collect { |version_name, _| version version_name }
    end

    def method_missing(method_name, *args, &block)
      return options[method_name.to_sym] if options.key?(method_name.to_sym)

      super
    end

    def respond_to_missing?(method_name, *args)
      options.key?(method_name.to_sym)
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

    Attachment.new self, name, definition
  end

  module ClassMethods
    def attachment(name, options = {})
      self.attachments = attachments.merge(name => options)

      define_method name do |version = nil, options = {}|
        return instance_variable_get("@#{name}") if version.nil?

        attachment(name).version(version, options)
      end

      define_method "#{name}=" do |value|
        self.updated_at = Time.now if respond_to?(:updated_at=) && !value.nil?

        instance_variable_set "@#{name}", value
      end
    end
  end
end

