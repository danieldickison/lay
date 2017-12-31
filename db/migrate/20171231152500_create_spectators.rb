class CreateSpectators < ActiveRecord::Migration[5.1]
  def change
    create_table :spectators do |t|
      t.string :name
      t.text :blah

      t.timestamps
    end
  end
end
