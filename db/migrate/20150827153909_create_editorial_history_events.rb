class CreateEditorialHistoryEvents < ActiveRecord::Migration
  def change
    create_table :editorial_history_events do |t|
      t.string :content_id, null: false
      t.datetime :timestamp
      t.references :user, foreign_key: true
      t.string :action
      t.integer :version
      t.references :event, foreign_key: true
      t.string :note
    end
  end
end
