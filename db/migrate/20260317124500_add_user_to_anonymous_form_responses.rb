class AddUserToAnonymousFormResponses < ActiveRecord::Migration[8.1]
  def change
    add_reference :anonymous_form_responses, :user, foreign_key: true

    add_index :anonymous_form_responses,
      [ :anonymous_form_id, :user_id ],
      unique: true,
      where: "user_id IS NOT NULL",
      name: "index_anonymous_form_responses_on_form_id_and_user_id_unique"
  end
end
