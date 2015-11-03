module Queries
  module GetLinked
    def self.call(content_id, link_type)
      if LiveContentItem.find_by(content_id: content_id).nil?
        error_details = {
          error: {
            code: 404,
            message: "Item with content_id: '#{content_id}', does not exist"
          }
        }

        raise CommandError.new(code: 404, error_details: error_details)
      else
        content_item_links = Link.where(target_content_id: content_id, link_type: link_type)

        if content_item_links.empty?
          []
        else
          content_item_links.map { |link| link.link_set.to_json }
        end
      end
    end
  end
end
