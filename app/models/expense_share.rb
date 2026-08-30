class ExpenseShare < ApplicationRecord
  belongs_to :expense_transaction, class_name: "Transaction", foreign_key: :transaction_id
  belongs_to :person

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :person_id, uniqueness: { scope: :transaction_id }
  validate :person_belongs_to_transaction_owner
  validate :transaction_is_an_expense

  def settled?
    settled_at.present?
  end

  def transaction
    expense_transaction
  end

  private
    def person_belongs_to_transaction_owner
      return if expense_transaction.blank? || person.blank?
      return if expense_transaction.user_id == person.user_id

      errors.add(:person, "must belong to the transaction owner")
    end

    def transaction_is_an_expense
      return if expense_transaction.blank? || expense_transaction.expense?

      errors.add(:expense_transaction, "must be an expense")
    end
end
