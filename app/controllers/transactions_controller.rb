class TransactionsController < ApplicationController
  before_action :set_transaction, only: %i[ destroy ]

  def index
    @transactions = current_user.transactions.order(date: :desc)
    @income = @transactions.income.sum(:amount)
    @expenses = @transactions.expense.sum(:amount)
    @balance = @income - @expenses
  end

  def new
    @transaction = current_user.transactions.new
  end

  def create
    @transaction = current_user.transactions.new(transaction_params)

    if @transaction.save
      redirect_to transactions_path, notice: "Movimiento registrado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @transaction.destroy
    redirect_to transactions_path, notice: "Eliminado.", status: :see_other
  end

  private
    def set_transaction
      @transaction = current_user.transactions.find(params[:id])
    end

    def transaction_params
      params.expect(transaction: [ :amount, :description, :transaction_type, :category, :date ])
    end
end
