# A resource is a model for first-class
# data from the API.  A Resource MUST have
# an `id` field, and it SHOULD correspond
# to a `GoodGuide::*` ActiveResource class.
#
# Unlike an Entity, a Resource is not necessarily rated.

require 'active_model'
require 'active_support/core_ext/hash'

require "faraday_middleware-multi_json"

require "purview_api/connection"
require "purview_api/cookie_auth"
require "purview_api/errors"
require "purview_api/response_list"
require "purview_api/resource/class_methods"

module PurviewApi
  module Resource
    def self.included(base)
      base.extend(ClassMethods)
      base.extend(ActiveModel::Naming)
      base.extend(ActiveModel::Translation)

      base.class_eval do
        attr_reader :errors, :attributes
        class_attribute :connection, :views, :json_root
        self.views = {}
        alias_method :resource, :attributes
        initialize_resource!
      end
    end

    def initialize(object = {})
      @errors = ActiveModel::Errors.new(self)

      case
      when Fixnum === object
        @attributes = { :id => object }
      when Hash === object
        @attributes = object.with_indifferent_access
      when object.respond_to?(:attributes)
        @attributes = object.attributes
      else
        @attributes = { :id => nil }
      end
    end

    def save
      errors.clear
      result = if id
                 connection.put(id, attributes)
               else
                 connection.post(attributes)
               end

      @attributes = result.with_indifferent_access if id.nil? || result.is_a?(Hash)
      true
    rescue Faraday::Error::ClientError => e
      if e.response
        !parse_errors(e.response[:body], e.response[:status])
      else
        raise e
      end
    end

    def save!
      return if save

      raise ResourceNotSaved.new(
        "Could not save #{self.class.name.demodulize}" +
        "#{@attributes.inspect}: " +
        "#{errors.full_messages.join(',')}", self)
    end

    def destroy
      return false unless id
      raise_not_destroyed('missing id') unless id
      raise_not_destroyed('missing catalog_id') unless attributes[:catalog_id]

      result = connection.delete(id, catalog_id: attributes[:catalog_id])
      !parse_errors(result)
    rescue Faraday::Error::ClientError => e
      !parse_errors(e.response[:body], e.response[:status])
    end

    def destroy!
      return if destroy

      raise_not_destroyed(errors.full_messages.join(','))
    end

    def id
      @attributes.fetch(:id, nil)
    end

    def get(elements, opts={})
      connection.get_all("#{id}/#{elements}", opts)
    end

    def put(elements, opts={})
      if elements.is_a?(Hash)
        opts = elements
        elements = nil
      end
      result = connection.put("#{id}/#{elements}", opts)
      @attributes = result.with_indifferent_access if result.is_a?(Hash)
      true
    rescue Faraday::Error::ClientError => e
      if e.response
        !parse_errors(e.response[:body], e.response[:status])
      else
        raise e
      end
    end

    def as_json(opts={})
      # Pull JSON from relations directly, because they may have been
      # modified/inflated
      opts[:methods] ||= []
      opts[:methods].concat(self.class.relations).uniq!

      @attributes.as_json(opts).merge(
        Hash[opts[:methods].map{|m| [m, self.send(m).as_json]}]
      )
    end

    private

    def raise_not_destroyed(message)
      raise ResourceNotDestroyed.new(
        "Could not destroy #{self.class.name.demodulize}" +
        "#{@attributes.inspect}: " +
        "#{message}", self)
    end
  end
end
