class ExpenseSplitsController < ApplicationController
  def index
    load_index_data
  end

  def create
    @share_rows = normalized_share_rows
    @transaction = current_user.transactions.new(transaction_attributes)

    validate_split_input
    if @transaction.errors.empty?
      ActiveRecord::Base.transaction do
        @transaction.save!
        @share_rows.each do |row|
          normalized_name = Person.normalize_name(row[:person_name])
          person = current_user.people.create_or_find_by!(normalized_name:) { |new_person| new_person.name = row[:person_name] }
          @transaction.expense_shares.create!(person:, amount: row[:amount])
        end
      end
      redirect_to expense_splits_path, notice: "Cuenta compartida guardada."
    else
      load_index_data
      render :index, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordInvalid => error
    @transaction.errors.add(:base, error.record.errors.full_messages.to_sentence)
    load_index_data
    render :index, status: :unprocessable_entity
  end

  def toggle
    share = ExpenseShare.joins(:expense_transaction).where(transactions: { user_id: current_user.id }).find(params[:id])
    share.update!(settled_at: share.settled_at? ? nil : Time.current)
    redirect_to expense_splits_path
  end

  private
    def load_index_data
      @people = current_user.people.order(:name)
      @transaction ||= current_user.transactions.new(date: Date.current)
      @split_transactions = current_user.transactions.expense
        .joins(:expense_shares).distinct.includes(expense_shares: :person).order(date: :desc, created_at: :desc)
      totals = current_user.people.joins(expense_shares: :expense_transaction)
        .where(expense_shares: { settled_at: nil }, transactions: { transaction_type: Transaction.transaction_types[:expense] })
        .group("people.id").sum("expense_shares.amount")
      @outstanding_totals = @people.filter_map { |person| [ person, totals[person.id] ] if totals[person.id].to_d.positive? }.to_h
      @share_rows ||= [ { person_name: "", amount: "" } ]
    end

    def normalized_share_rows
      raw = params.dig(:split, :shares)
      values = raw.respond_to?(:each_value) ? raw.each_value.to_a : Array(raw)
      values.filter_map do |row|
        row = row.to_unsafe_h if row.respond_to?(:to_unsafe_h)
        name = (row[:person_name] || row["person_name"]).to_s.strip
        amount = (row[:amount] || row["amount"]).to_s.strip
        next if name.blank? && amount.blank?

        { person_name: name, amount: amount }
      end
    end

    def transaction_attributes
      params.expect(split: [ :description, :total_amount, :amount, :date ]).slice(:description, :date).merge(
        amount: params.dig(:split, :total_amount).presence || params.dig(:split, :amount),
        category: "food",
        transaction_type: :expense
      )
    end

    def validate_split_input
      @transaction.valid?
      if @share_rows.empty?
        @transaction.errors.add(:base, "Add at least one person")
        return
      end

      normalized_names = @share_rows.map { |row| Person.normalize_name(row[:person_name]) }
      @transaction.errors.add(:base, "El nombre de cada persona es obligatorio") if normalized_names.any?(&:blank?)
      @transaction.errors.add(:base, "Cada persona debe aparecer una sola vez") if normalized_names.uniq.length != normalized_names.length

      total_amount = currency_amount(params.dig(:split, :total_amount).presence || params.dig(:split, :amount))
      amounts = @share_rows.map { |row| currency_amount(row[:amount]) }
      @transaction.errors.add(:amount, "debe usar como máximo dos decimales") if total_amount.nil?
      if amounts.any?(&:nil?) || amounts.any? { |amount| amount <= 0 }
        @transaction.errors.add(:base, "Los montos deben ser positivos y usar como máximo dos decimales")
      elsif total_amount && amounts.sum > total_amount
        @transaction.errors.add(:base, "Los montos asignados no pueden superar el total")
      end
    end

    def currency_amount(value)
      amount = BigDecimal(value.to_s, exception: false)
      return if amount.nil? || !amount.finite? || amount <= 0 || amount > BigDecimal("99999999.99")

      amount if amount * 100 == (amount * 100).to_i
    end
end
