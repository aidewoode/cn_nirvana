class RemoveFakeNameToUser < ActiveRecord::Migration
  def change

    remove_column :users, :fake_name 
    add_column :users, :fake , :string
  end
end
