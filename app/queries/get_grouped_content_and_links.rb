module Queries
  module GetGroupedContentAndLinks
    PAGE_SIZE = 100
    #Document = Struct.new
    #LinkSetDetails = Struct.new
    #ContentItemDetails = Struct.new
    
    # return array useful objects
    def self.call(last_seen_content_id: '00000000-0000-0000-0000-000000000000', page_size: PAGE_SIZE)
      content_ids = query_content_ids_for_page(last_seen_content_id: last_seen_content_id, page_size: page_size)

      if content_ids.empty?
        []
      else
        content_results(content_ids).to_a

        # TODO:
        # - group content items by content_id
        # - include links
        # - decide what to pass to the presenter
      end
    end

  private

    def self.group_results(content_result_set, link_set_result_set)
      content = content_result_set.group_by(&:content_id)
      links = link_set_result_set.group_by(&:content_id)

      content.each do |content_id, content_details|
        link_set_details = build_links(links[content_id])
        content_details = build_content(content_details)
        Document.new(content_id, content_details, link_set_details)
      end
    end

    def self.query_content_ids_for_page(last_seen_content_id:, page_size:)
      ContentItem
        .select(:content_id)
        .group(:content_id)
        .having("content_id > ?", [last_seen_content_id])
        .limit(page_size)
        .map(&:content_id)
    end

    def self.content_results(content_ids)
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

        WHERE ci.content_id IN (#{content_id_placeholders_sql(content_ids)})
      SQL

      ActiveRecord::Base.connection.raw_connection.exec(query, content_ids)
    end

    def self.content_id_placeholders_sql(content_ids)
      (1).upto(content_ids.size).map { |i| "$#{i}" }.join(',')
    end
  end
end
