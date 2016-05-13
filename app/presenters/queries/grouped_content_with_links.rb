module Presenters
  module Queries
    class GroupedContentWithLinks
      def initialize(results)
        @results = results
        @paginator = nil
      end

      def present
        {
          last_seen_content_id: last_seen_content_id,
          results: present_results,
        }
      end

    private
      attr_accessor :results

      def present_results
        results.map { |result| present_result(result) }
      end

      def last_seen_content_id
        return nil if results.empty?

        results.last["content_id"]
      end

      def present_result(query_result)
        {
          content_id: query_result[:content_id],
          content_items: present_content_items(query_result[:content_items]),
          links: present_links(query_result[:links])
        }
      end

      def present_content_items(content_items)
        content_items.map { |content_item| present_content_item(content_item) }
      end

      def present_content_item(content_item)
        {
          locale: content_item.fetch("locale"),
          base_path: content_item.fetch("base_path"),
          publishing_app: content_item.fetch("publishing_app"),
          format: content_item.fetch("format"),
          user_facing_version: content_item.fetch("user_facing_version"),
          state: content_item.fetch("state"),
        }
      end

      # Links is an array of individual link rows
      # So we need to group them by type
      def present_links(links)
        groups = links.group_by {|link| link.fetch("link_type")}
        links_hash = {}

        groups.each do |link_type, links|
          links_hash[link_type.to_sym] = links.map do |link|
            {content_id: link.fetch("target_content_id")}
          end
        end

        links_hash
      end
    end
  end
end
