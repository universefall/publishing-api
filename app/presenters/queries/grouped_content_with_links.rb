module Presenters
  module Queries
    class GroupedContentWithLinks
      def initialize(results)
        @results = results
      end

      def present
        {
          "page": 1,
          "results": present_results,
        }
      end

    private
      attr_accessor :results

      def present_results
        []
      end
    end


  end
end
