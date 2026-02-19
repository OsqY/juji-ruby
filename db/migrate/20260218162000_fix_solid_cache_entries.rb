class FixSolidCacheEntries < ActiveRecord::Migration[8.1]
  def up
    # Drop the incorrect tables if they exist
    drop_table :solid_cache_tables, if_exists: true
    drop_table :solid_cache_entries, if_exists: true

    # Create the table correctly
    create_table :solid_cache_entries do |t|
      t.binary   :key,        null: false
      t.binary   :value,      null: false
      t.integer  :key_hash,   limit: 8, null: false
      t.integer  :byte_size,  null: false
      t.datetime :created_at, null: false

      t.index    :key_hash,   unique: true, name: "index_solid_cache_entries_on_key_hash"
      t.index    [ :key_hash, :byte_size ], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
      t.index    :created_at, name: "index_solid_cache_entries_on_created_at"
    end
  end

  def down
    drop_table :solid_cache_entries
  end
end
