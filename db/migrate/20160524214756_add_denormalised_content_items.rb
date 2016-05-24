class AddDenormalisedContentItems < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE TABLE "content_items_dn" AS (
        SELECT
          "content_items".*,
          "locations"."base_path",
          "states"."name",
          "translations"."locale",
          "user_facing_versions"."number"
        FROM "content_items"
        INNER JOIN "locations" ON "locations"."content_item_id" = "content_items"."id"
        INNER JOIN "states" ON "states"."content_item_id" = "content_items"."id"
        INNER JOIN "translations" ON "translations"."content_item_id" = "content_items"."id"
        INNER JOIN "user_facing_versions" ON "user_facing_versions"."content_item_id" = "content_items"."id"
        WHERE "states"."name" <> 'unpublished' -- Temporary for testing purposes. See ContentItemUniquenessValidator
      )
    SQL

    add_index :content_items_dn, [:base_path, :name, :locale, :number], unique: true, name: "pillars_of_uniqueness"
    add_index :content_items_dn, :content_id
    add_index :content_items_dn, :document_type
    add_index :content_items_dn, :format
    add_index :content_items_dn, :public_updated_at
    add_index :content_items_dn, :publishing_app
    add_index :content_items_dn, :rendering_app
    add_index :content_items_dn, :base_path
    add_index :content_items_dn, :name
    add_index :content_items_dn, :locale
    add_index :content_items_dn, :number

    execute %{ALTER TABLE "content_items_dn" ADD PRIMARY KEY ("id")}
    execute %{ALTER TABLE "content_items_dn" ALTER COLUMN "id" SET DEFAULT nextval('content_items_id_seq'::regclass)}
  end

  def down
    drop_table :content_items_dn
  end
end
