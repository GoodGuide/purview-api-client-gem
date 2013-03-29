module GoodGuide
  module EntitySoup
    module Search
      def morelikethis(params = {})
        find_all({:elements => 'morelikethis'}.merge(params))
      end

      def autocompletion(params = {})
        find_all({:elements => 'autocompletion'}.merge(params))
      end

      def spelling(params = {})
        find_all({:elements => 'spelling'}.merge(params))
      end

      def search(params = {})
        find_all({:elements => 'search'}.merge(params))
      end
    end
  end
end
