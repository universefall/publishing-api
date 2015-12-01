require "csv"

class CleanupWhitehallData < ActiveRecord::Migration
  def up
    content_item_db_ids_matched_by_base_path = []

    CSV.foreach(Rails.root + "db/migrate/20151201130626_cleanup_whitehall_data.csv", headers: true) do |row|
      whitehall_db_id = row["whitehall_db_id"]
      content_id = row["content_id"]
      base_path = row["base_path"]
      locale = row["locale"]
      state = row["state"]

      content_item = DraftContentItem.find_by(base_path: base_path, locale: locale)
      next unless content_item

      content_item_db_ids_matched_by_base_path << content_item.id

      if content_id && content_id != content_item.content_id
        puts "Would update #{content_item.content_id} to #{content_id}"
        # content_item.update_column(:content_id, content_id)
      end
    end

    content_items_to_delete = DraftContentItem.where(publishing_app: 'whitehall').where.not(id: content_item_db_ids_matched_by_base_path)
    content_items_to_delete.each do |item|
      puts "Would delete #{item.content_id} because #{item.base_path} is not in whitehall"
    end
  end
end
