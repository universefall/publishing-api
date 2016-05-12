module Queries
  module GetGroupedContentAndLinks
    PAGE_SIZE = 10.freeze
    DEFAULT_CONTENT_ID = '00000000-0000-0000-0000-000000000000'.freeze

    # return array useful objects
    def self.call(last_seen_content_id: DEFAULT_CONTENT_ID, page_size: PAGE_SIZE)
      content_ids = query_content_ids_for_page(
        last_seen_content_id: last_seen_content_id,
        page_size: page_size
      )

      # TODO:
      # - decide what to pass to the presenter
      # - decide the structure
      # - decide states
      group_results(content_results(content_ids), link_set_results(content_ids))
    end

  private

    def self.query_content_ids_for_page(last_seen_content_id:, page_size:)
      ContentItem
        .select(:content_id)
        .group(:content_id)
        .having("content_id > ?", [last_seen_content_id])
        .limit(page_size)
        .map(&:content_id)
    end

    def self.group_results(content_results, link_set_results)
      grouped_content_items = group_content_results_by_content_id(content_results)
      grouped_links = group_link_set_by_content_id(link_set_results)

      grouped_content_items.map do |content_id, content_items|
        {
          content_id: content_id,
          content_items: content_items,
          links: grouped_links[content_id] || []
        }
      end
    end

    def self.group_content_results_by_content_id(content_results)
      content_results.group_by { |item| item["content_id"] }
    end

    def self.group_link_set_by_content_id(link_set_results)
      link_set_results.group_by { |link_set| link_set["content_id"] }
    end

    def self.link_set_results()
    end

    def self.content_results(content_ids)
      return [] if content_ids.empty?

      query = <<-SQL
        SELECT
          ci.content_id as content_id,
          ci.id as content_item_id,
          t.locale as locale,
          loc.base_path as base_path,
          s.name as state,
          ufv.number as version

        FROM
          content_items ci
        JOIN translations t on t.content_item_id = ci.id
        JOIN locations loc on loc.content_item_id = ci.id
        JOIN states s on s.content_item_id = ci.id
        JOIN user_facing_versions ufv on ufv.content_item_id = ci.id

        WHERE ci.content_id IN (#{sql_value_placeholders(content_ids)})
      SQL

      ActiveRecord::Base.connection.raw_connection.exec(query, content_ids)
    end

    def self.link_set_results(content_ids)
      return [] if content_ids.empty?

      query = <<-SQL
        SELECT
          link_sets.content_id,
          links.link_type,
          links.target_content_id
        FROM
          link_sets
        JOIN
          links on link_sets.id = links.link_set_id

        WHERE link_sets.content_id IN (#{sql_value_placeholders(content_ids)})
      SQL

      ActiveRecord::Base.connection.raw_connection.exec(query, content_ids)
    end

    def self.sql_value_placeholders(resource)
      (1).upto(resource.size).map { |i| "$#{i}" }.join(',')
    end
  end
end
