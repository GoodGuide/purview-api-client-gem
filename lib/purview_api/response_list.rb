module PurviewApi
  class ResponseList < Array
    def stats
      @stats ||= HashWithIndifferentAccess.new
    end

    def stats=(s={})
      @stats = s.with_indifferent_access
    end
  end
end

