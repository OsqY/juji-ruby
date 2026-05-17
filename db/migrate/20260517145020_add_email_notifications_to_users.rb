class AddEmailNotificationsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :notify_by_email, :boolean, default: false
    add_column :users, :email_frequency, :string, default: "daily"
    add_column :users, :last_email_sent_at, :datetime
  end
end
