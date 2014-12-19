
require "swift_client"

module Attachments
  class SwiftDriver
    attr_accessor :swift_client

    def initialize(swift_client)
      self.swift_client = swift_client
    end

    def store(name, data, container, headers = {})
      swift_client.put_object name, data, container, headers
    end 

    def value(name, container)
      swift_client.get_object(name, container).body
    end 

    def delete(name, container)
      swift_client.delete_object name, container
    rescue SwiftClient::ResponseError => e
      return true if e.code == 404

      raise e
    end 

    def exists?(name, container)
      swift_client.head_object name, container

      true
    rescue SwiftClient::ResponseError => e
      return false if e.code == 404

      raise e
    end 

    def temp_url(name, container, options = {})
      swift_client.temp_url name, container, options
    end
  end
end

