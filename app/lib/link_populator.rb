class LinkPopulator
  def self.create_or_replace(link_set, links)
    content_item_links = Link.where(link_set: link_set)

    if links.nil? || links.empty?
      delete_old_content_item_links(link_set)
    elsif content_item_links.nil? || content_item_links.empty?
      add_content_item_links(link_set, links)
    else
      delete_old_content_item_links(link_set)
      add_content_item_links(link_set, links)
    end
  end

  def self.add_content_item_links(link_set, links)
    links.each do |link_type, links|
      links.each do |link|
        Link.new(
          link_set: link_set,
          target_content_id: link,
          link_type: link_type,
        ).save!
      end
    end
  end

  def self.delete_old_content_item_links(link_set)
    Link.where(link_set: link_set).delete_all
  end
end
