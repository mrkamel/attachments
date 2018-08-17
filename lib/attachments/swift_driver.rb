
require "swift_client"
require "connection_pool"

module Attachments
  class SwiftDriver
    attr_accessor :swift_client_pool

    def initialize(swift_client_pool)
      self.swift_client_pool = swift_client_pool
    end

    def list(container, prefix: nil)
      return enum_for(:list, container, prefix: prefix) unless block_given?

      swift_client_pool.with do |swift_client|
        swift_client.paginate_objects(container, prefix: prefix) do |response|
          response.parsed_response.each do |source_object|
            yield source_object["name"]
          end
        end
      end
    end

    def store(name, data_or_io, container, headers = {})
      swift_client_pool.with do |swift_client|
        swift_client.put_object name, data_or_io, container, headers
      end
    end 

    def value(name, container)
      swift_client_pool.with do |swift_client|
        swift_client.get_object(name, container).body
      end
    end 

    def delete(name, container)
      swift_client_pool.with do |swift_client|
        swift_client.delete_object name, container
      end
    rescue SwiftClient::ResponseError => e
      return true if e.code == 404

      raise e
    end 

    def exists?(name, container)
      swift_client_pool.with do |swift_client|
        swift_client.head_object name, container
      end

      true
    rescue SwiftClient::ResponseError => e
      return false if e.code == 404

      raise e
    end 

    def temp_url(name, container, options = {})
      swift_client_pool.with do |swift_client|
        swift_client.temp_url name, container, options
      end
    end
  end
end

