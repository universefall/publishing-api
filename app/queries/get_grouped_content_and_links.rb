module Queries
  module GetGroupedContentAndLinks
    PAGE_SIZE = 100
    #Document = Struct.new
    #LinkSetDetails = Struct.new
    #ContentItemDetails = Struct.new
    
    # return array useful objects
    def self.call(last_seen_content_id: nil, page_size: PAGE_SIZE)
    end

  private
    def group_results(content_result_set, link_set_result_set)
      content = content_result_set.group_by(&:content_id)
      links = link_set_result_set.group_by(&:content_id)

      content.each do |content_id, content_details|
        link_set_details = build_links(links[content_id])
        content_details = build_content(content_details)
        Document.new(content_id, content_details, link_set_details)
      end
    end

    def content_results(last_seen_content_id: nil, page_size: 100)
      ActiveRecord::Base.connection.execute
    end

    def link_results(last_seen_content_id: nil, page_size: 100)
      ActiveRecord::Base.connection.execute
    end

    def build_links

    end

    def build_content

    end
  end
end
