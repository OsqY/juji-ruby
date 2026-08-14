require "test_helper"
require_relative "../../db/migrate/20260810000000_backfill_user_invite_tokens"

class BackfillUserInviteTokensTestRecord < ActiveRecord::Base
  self.abstract_class = true
end

class BackfillUserInviteTokensTest < ActiveSupport::TestCase
  test "backfills missing invite tokens and enforces the constraint" do
    record_class = BackfillUserInviteTokensTestRecord
    record_class.establish_connection(adapter: "sqlite3", database: ":memory:")
    connection = record_class.connection

    connection.create_table(:users) { |table| table.string :invite_token }
    connection.add_index(:users, :invite_token, unique: true)
    connection.execute("INSERT INTO users (invite_token) VALUES (NULL), ('existing-token')")

    migration = BackfillUserInviteTokens.new
    migration.define_singleton_method(:connection) { connection }
    migration.up

    tokens = connection.select_values("SELECT invite_token FROM users ORDER BY id")
    assert_equal 2, tokens.length
    assert_includes tokens, "existing-token"
    assert tokens.all?(&:present?)
    assert_not connection.columns(:users).find { |column| column.name == "invite_token" }.null
    assert_raises(ActiveRecord::NotNullViolation) do
      connection.execute("INSERT INTO users (invite_token) VALUES (NULL)")
    end

    invite_token_index = connection.indexes(:users).find { |index| index.columns == [ "invite_token" ] }
    assert invite_token_index&.unique

    migration.down
    assert connection.columns(:users).find { |column| column.name == "invite_token" }.null
  ensure
    record_class&.connection_pool&.disconnect!
  end
end
