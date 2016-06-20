
require "swift_client"

module Attachments
  class SwiftDriver
    attr_accessor :swift_client_pool

    def initialize(swift_client_pool)
      self.swift_client_pool = swift_client_pool
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

