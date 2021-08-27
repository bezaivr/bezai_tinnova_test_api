class CreateBeers < ActiveRecord::Migration[5.2]
  def change
    create_table :beers do |t|
      t.integer :api_id
      t.datetime :seen_at
      t.boolean :favorite, null: false, default: false
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
