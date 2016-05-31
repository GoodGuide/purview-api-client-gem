module PurviewApi
  module Resource
    class ResourceNotFound < StandardError
      attr_reader :resource

      def initialize(message = nil, resource = nil)
        @resource = resource
        super(message)
      end
    end
  end

  module Resource
    class ResourceNotSaved < StandardError
      attr_reader :resource

      def initialize(message = nil, resource = nil)
        @resource = resource
        super(message)
      end
    end
  end

  module Resource
    class ResourceNotDestroyed < StandardError
      attr_reader :resource

      def initialize(message = nil, resource = nil)
        @resource = resource
        super(message)
      end
    end
  end
end
