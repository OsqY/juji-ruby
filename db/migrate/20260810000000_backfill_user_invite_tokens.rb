class BackfillUserInviteTokens < ActiveRecord::Migration[8.1]
  def up
    user_ids = connection.select_values("SELECT id FROM users WHERE invite_token IS NULL")
    user_ids.each { |user_id| backfill_user(user_id) }
    change_column_null :users, :invite_token, false
  end

  def down
    change_column_null :users, :invite_token, true
  end

  private
    def backfill_user(user_id)
      loop do
        token = SecureRandom.urlsafe_base64(16)
        updated = connection.transaction(requires_new: true) do
          users = Arel::Table.new(:users)
          statement = users.where(
            users[:id].eq(bind("id", user_id)).and(users[:invite_token].eq(nil))
          ).compile_update(users[:invite_token] => bind("invite_token", token))

          connection.update(statement, "BackfillUserInviteTokens")
        end

        return if updated.zero?
      rescue ActiveRecord::RecordNotUnique
        # Retry with a new token if the unique index detects a collision.
      end
    end

    def bind(name, value)
      column = connection.schema_cache.columns_hash("users").fetch(name)
      Arel::Nodes::BindParam.new(
        ActiveRecord::Relation::QueryAttribute.new(name, value, column.fetch_cast_type(connection))
      )
    end
end
