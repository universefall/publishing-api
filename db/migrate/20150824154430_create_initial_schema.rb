class CreateEvents < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
    end

    create_table :events do |t|
      t.string :name, null: false
      t.json :payload, null: false

      t.references :user, foreign_key: { on_delete: :restrict }

      t.timestamps
    end

    create_table :draft_content_items do |t|
      t.string :base_path
      t.string :content_id
      t.string :locale
      t.string :title
      t.string :description
      t.string :format
      t.datetime :public_updated_at

      t.json :details, null: false

      t.references :user, foreign_key: { on_delete: :restrict }
    end

    create_table :live_content_items do |t|
      t.string :base_path
      t.string :content_id
      t.string :locale
      t.string :title
      t.string :description
      t.string :format
      t.datetime :public_updated_at

      t.json :details, null: false

      t.references :user, foreign_key: { on_delete: :restrict }
    end
  end
end
