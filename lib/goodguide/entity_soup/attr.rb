require 'hashie/mash'
module GoodGuide
  module EntitySoup

    class Attr
      include Resource

      attributes :type, :name, :options, :entity_type, :catalog_id, :schema

      default_view :include => ['schema']
      view :bare, {:inherits => nil, :schema => nil}

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
end
