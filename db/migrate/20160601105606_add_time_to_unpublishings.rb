class AddTimeToUnpublishings < ActiveRecord::Migration
  def change
    add_column :unpublishings, :time, :datetime
  end
end
