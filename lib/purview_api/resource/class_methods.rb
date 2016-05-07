module PurviewApi
  module Resource
    module ClassMethods
      def initialize_resource!
        resource_name self.name.demodulize.underscore
        resource_path self.resource_name.pluralize
      end

      def find(id, opts={})
        params = view_params_for(opts)
        if id.is_a?(Array)
          found_resources = find_all(opts.merge(:id => id))
          # NOTE: ActiveRecord throws an exception if id isn't found - here
          # we just insert a nil
          result = id.collect do |requested_id|
            found_resources.find do |resource|
              resource.id == requested_id
            end
          end
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

        connection.get_all(
          elements, params.merge!(:json_root => self.json_root)
        ).map! do |resource|
          new(resource)
        end
      rescue Faraday::Error::ResourceNotFound => e
        # NOTE: can currently happen if find params reference a
        # non-existent entity, a bug in EntitySoup?
        PurviewApi::ResponseList.new
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
        full_path = "#{PurviewApi.api_path}/#{path}"
        self.connection = PurviewApi::Connection.new(full_path)
      end

      def resource_json_root(json_root)
        self.json_root = json_root
      end

      private

      def view_params_for(opts)
        params = merge_params(nil, opts)

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
