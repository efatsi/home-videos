class CreateVideos < ActiveRecord::Migration[7.2]
  def change
    create_table :videos do |t|
      t.string :spaces_key, null: false, index: { unique: true }
      t.string :title
      t.datetime :recorded_at
      t.integer :duration
      t.string :thumbnail_key
      t.bigint :file_size

      t.timestamps
    end
  end
end
