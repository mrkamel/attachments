
module Attachments
  class UnknownAttachment < StandardError; end
  class NoSuchVersion < StandardError; end

  def self.driver=(driver)
    @driver = driver
  end

  def self.driver
    @driver
  end

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
        url_prefix = option(:url_prefix) ? option(:url_prefix).gsub(/$/, "/") : ""

        "#{option :protocol}://#{option :host}/#{url_prefix}#{path}"
      end

      def path
        option :path
      end

      def container
        option :container
      end

      def temp_url(opts = {})
        driver.temp_url path, container, opts
      end

      def value
        driver.value path, container
      end

      def store(io_or_data, opts = {})
        driver.store path, io_or_data, container, opts
      end

      def delete
        driver.delete path, container
      end

      def exists?
        driver.exists? path, container
      end

      def inspect
        to_s
      end

      def object
        attachment.object
      end

      private

      def driver
        Attachments.driver
      end

      def option(option_name)
        return evaluate(attachment.options[:versions][name][option_name]) if attachment.options[:versions][name].key?(option_name)
        return evaluate(options[option_name]) if options.key?(option_name)
        return evaluate(attachment.options[option_name]) if attachment.options.key?(option_name)

        evaluate Attachments.default_options[option_name]
      end

      def evaluate(option)
        return option unless option.is_a?(String)

        option.gsub(/:[a-zA-Z0-9_]+/) do |name|
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

