class AddUserInformationToUser < ActiveRecord::Migration
  def change
    add_column :users, :fake_name, :string
    add_column :users, :city, :string
    add_column :users, :info, :text
  end
end
