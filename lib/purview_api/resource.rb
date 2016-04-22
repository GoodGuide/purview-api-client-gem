# A resource is a model for first-class
# data from the API.  A Resource MUST have
# an `id` field, and it SHOULD correspond
# to a `GoodGuide::*` ActiveResource class.
#
# Unlike an Entity, a Resource is not necessarily rated.

require 'active_model'
require 'active_model/validations'

module GoodGuide
  module EntitySoup
    module Resource

      def self.included(base)
        base.extend(ClassMethods)
        base.extend(ActiveModel::Naming)
        base.extend(ActiveModel::Translation)

        base.class_eval do
          attr_reader :errors
          attr_reader :attributes
          class_attribute :connection, :views, :json_root
          self.views = {}
          alias_method :resource, :attributes
          initialize_resource!
        end
      end

      def initialize(o = {})
        @errors = ActiveModel::Errors.new(self)

        case
        when Fixnum === o
          @attributes = { :id => o }
        when Hash === o
          @attributes = o.with_indifferent_access
        when o.respond_to?(:attributes)
          @attributes = o.attributes
        else
          @attributes = { :id => nil }
          super
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

      def destroy
        if id
            result = connection.delete(id, attributes)
            !parse_errors(result)
        else
          false
        end
      rescue Faraday::Error::ClientError => e
        !parse_errors(e.response[:body], e.response[:status])
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

      module ClassMethods
        def inherited(child)
          child.initialize_resource!
        end

        def initialize_resource!
          resource_name self.name.demodulize.underscore
          resource_path self.resource_name.pluralize
        end

        def default_view(params)
          self.views = views.merge(:default => merge_params(views[:default], params))
        end

        def view(name, params)
          inherits = params.fetch(:inherits, :default)
          params.delete(:inherits)

          self.views = if inherits
            views.merge(name => merge_params(views[inherits], params))
          else
            views.merge(name => params)
          end
        end

        def find(id, opts={})
          params = view_params_for(opts)
          if id.is_a?(Array)
            found_resources = find_all(opts.merge(:id => id))
            # NOTE: ActiveRecord throws an exception if id isn't found - here we just insert a nil
            result = id.collect {|requested_id| found_resources.find { |resource| resource.id == requested_id } }
          else
            result = connection.get(id, params)
            new(result)
          end
        rescue Faraday::Error::ResourceNotFound => e
          nil
        end

        def find_all(opts={})
          params = view_params_for(opts)
          elements = params.delete(:elements)

          connection.get_all(elements, params.merge!(:json_root => self.json_root)).map! { |r| new(r) }
        rescue Faraday::Error::ResourceNotFound => e
          # NOTE: can currently happen if find params reference a non-existent entity, a bug in EntitySoup?
          GoodGuide::EntitySoup::Connection::ResponseList.new
        end

        def get(elements, opts={})
          params = view_params_for(opts)
          connection.get_all(elements, params)
        end

        def post(elements, opts={})
          params = view_params_for(opts)
          new(connection.post(elements, params))
        end

        def name
          super.split('::').last
        end

        def resource_name(name=nil)
          if name
            @resource_name = name.to_s
            alias_method name.to_sym, :resource
          end
          @resource_name
        end

        def resource_path(path)
          self.connection = GoodGuide::EntitySoup::Connection.new("#{resource_version_path}/#{path}")
        end

        def resource_version(version = nil)
          @version ||= (version || GoodGuide::EntitySoup.api_version)
        end

        def resource_version_path
          "api/v#{resource_version.split('.').first}"
        end

        def resource_json_root(json_root)
          self.json_root = json_root
        end

      private

        def view_params_for(opts)
          view = opts.fetch(:view, :default)
          opts.delete(:view)

          params = if view
            merge_params(views[view], opts)
          else
            opts
          end

          if params[:exclude] && params[:include]
            params[:exclude] = params[:exclude].split(',') if params[:exclude].is_a? String
            params[:include] = params[:include].split(',') if params[:include].is_a? String
            params[:include] -= params[:exclude]
          end

          params
        end

        def deep_copy(object)
          Marshal.load( Marshal.dump( object ) )
        end

        def merge_params(one, two)
          two = deep_copy(two) || {}
          one = deep_copy(one) || {}

          # smart merge known array keys
          %w(include ratings).map(&:to_sym).each do |k|
            if two.has_key?(k) and two[k].nil?
              one.delete(k)
            else
              (one[k] ||= []).concat(Array.wrap(two.delete(k))).uniq!

              # don't send additional params if they're not needed
              one.delete(k) if one[k].empty?
            end
          end

          one.merge(two)
        end

        # shortcut for direct method accessors to
        # attributes of the returned hash
        def attributes(*attrs)
          attrs.each do |attr|
            define_method(attr) do
              self.resource[attr]
            end
            define_method("#{attr}=") do |value|
              self.resource[attr] = value
            end
          end
        end

        # define a method that essentially does ||=
        def define_cached_method(name, &method)
          ivar = "@#{name}"
          define_method(name) do |*a, &b|
            if instance_variable_defined?(ivar)
              return instance_variable_get(ivar)
            end

            instance_variable_set(ivar, method.bind(self).call(*a, &b))
          end
        end
      end

      private

      # re-wrap this object with new data from the API
      def inflate!(opts={})
        new = self.class.find(self.id)
        resource.merge!(new.resource)

        self
      end

      def parse_errors(body, status = 0)
        case status / 100
        when 4
          error_info = nil
          begin
            error_info = JSON.load(body)
            if error_info.is_a?(Hash) and error_info['errors']
            error_info['errors'].each {|field, messages| errors.add(field.to_sym, messages)}
            else
              errors.add(:base, ["unknown client error #{status}"])
            end
          rescue JSON::ParserError => e
            errors.add(:base, ["unparseable client error #{status} #{e}"])
          end
          true
        when 5
          errors.add(:base, ["server error #{status}"])
          true
        else
          false
        end
      end

    end
  end
end
