require 'hashie/mash'
require "purview_api/resource"

module PurviewApi
  class Field
    include Resource

    attributes :type, :name, :entity_type, :catalog_id, :listing_id, :required

    def self.types(options = {})
      connection.get('types', options).collect { |t| Hashie::Mash.new(t) }
    end

    def enum
      enum = {}
      if options[:enum] and options[:enum_titles]
        options[:enum].zip(options[:enum_titles]).each do |(key, value)|
          enum[key] = value
        end
      end

      enum
    end

    def label_for(value)
      enum[value] || value
    end
  end
end
