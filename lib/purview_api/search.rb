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
        find_all(params)
      end

      def search_in_batches(params, &block)
        max_rows = params.delete(:max_rows) || 0
        batch_size = params.delete(:batch_size) || 50
        start = params.delete(:start) || 0

        results = []
        begin
          if (max_rows > 0) and ((start + batch_size) > max_rows)
            batch_size = max_rows - start
          end
          result = search(params.merge(rows: batch_size, start: start))
          unless result.blank?
            start += result.length
            if block_given?
              results.concat(block.call(result))
            else
              results.concat(result)
            end
          end
        end while not result.empty? and ((results.length < max_rows) or (max_rows == 0)) and (start < result.stats[:total])
        results
      end
    end
  end
end
