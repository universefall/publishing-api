class PopulateLinksTable < ActiveRecord::Migration
  def change
      LinkSet.all.each do |link_set|
      puts "Creating #{link_set.content_id} links"
      LinkPopulator.create_or_replace(link_set.id, link_set.links)
    end
  end
end
