class CreateMedals < ActiveRecord::Migration[7.0]
  def change
    create_table :medals do |t|
      t.integer :tokenid
      t.string :address

      t.timestamps
    end
  end
end
