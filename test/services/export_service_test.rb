require "test_helper"
require "csv"

class ExportServiceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email_address: "export@test.com", password: "password123", password_confirmation: "password123")
  end

  # Transaction CSV Export Tests
  test "export_transactions_csv generates valid CSV" do
    Transaction.create!(user_id: @user.id, description: "Test", category: "Food", amount: 50.00, date: Time.zone.today, transaction_type: "expense")
    
    csv_data = ExportService.to_csv(@user, "transactions")
    csv = CSV.parse(csv_data, headers: true)
    
    assert csv.count == 1
    assert csv.first["Descripcion"] == "Test"
  end

  test "export_transactions_csv respects category filter" do
    Transaction.create!(user_id: @user.id, description: "Food", category: "Food", amount: 30.00, date: Time.zone.today, transaction_type: "expense")
    Transaction.create!(user_id: @user.id, description: "Transport", category: "Transport", amount: 50.00, date: Time.zone.today, transaction_type: "expense")
    
    filters = { category: "food" }
    csv_data = ExportService.to_csv(@user, "transactions", filters)
    csv = CSV.parse(csv_data, headers: true)
    
    assert csv.count == 1
    assert csv.first["Categoria"] == "food"
  end

  # Reports CSV Export Tests
  test "export_reports_csv generates valid CSV with report data" do
    DailyReport.create!(user_id: @user.id, report_date: Time.zone.today, work_title: "Great day", worked_by: "Me", yesterday: "Rest", today: "Work")
    
    csv_data = ExportService.to_csv(@user, "reports")
    csv = CSV.parse(csv_data, headers: true)
    
    assert csv.count == 1
    assert csv.first["Titulo Trabajo"] == "Great day"
  end

  # Projects CSV Export Tests
  test "export_projects_csv generates valid CSV with project data" do
    Project.create!(user_id: @user.id, name: "Website", description: "Build website", target_date: Time.zone.today + 30.days)
    
    csv_data = ExportService.to_csv(@user, "projects")
    csv = CSV.parse(csv_data, headers: true)
    
    assert csv.count == 1
    assert csv.first["Nombre"] == "Website"
  end

  test "export_projects_csv includes task progress" do
    project = Project.create!(user_id: @user.id, name: "Website", description: "Build", target_date: Time.zone.today + 30.days)
    ProjectTask.create!(project_id: project.id, name: "Task 1", completed: true)
    ProjectTask.create!(project_id: project.id, name: "Task 2", completed: false)
    
    csv_data = ExportService.to_csv(@user, "projects")
    csv = CSV.parse(csv_data, headers: true)
    
    assert csv.first["Progreso"] == "50.0%"
  end

  # Habits CSV Export Tests
  test "export_habits_csv generates valid CSV with habit data" do
    Habit.create!(user_id: @user.id, name: "Exercise")
    
    csv_data = ExportService.to_csv(@user, "habits")
    csv = CSV.parse(csv_data, headers: true)
    
    assert csv.count == 1
    assert csv.first["Habito"] == "Exercise"
  end

  test "export_habits_csv calculates completion rate" do
    habit = Habit.create!(user_id: @user.id, name: "Exercise")
    HabitLog.create!(habit_id: habit.id, completed: true, log_date: Time.zone.today)
    HabitLog.create!(habit_id: habit.id, completed: false, log_date: 1.day.ago.to_date)
    
    csv_data = ExportService.to_csv(@user, "habits")
    csv = CSV.parse(csv_data, headers: true)
    
    assert csv.first["Tasa Cumplimiento"] == "50.0%"
  end

  # PDF Export Tests
  test "export_transactions_pdf generates valid PDF" do
    Transaction.create!(user_id: @user.id, description: "Test", category: "Food", amount: 50.00, date: Time.zone.today, transaction_type: "expense")
    
    pdf_data = ExportService.to_pdf(@user, "transactions")
    
    assert pdf_data.is_a?(String)
    assert pdf_data.start_with?("%PDF")
  end

  test "export_reports_pdf generates valid PDF" do
    DailyReport.create!(user_id: @user.id, report_date: Time.zone.today, work_title: "Test", worked_by: "Me", yesterday: "Test", today: "Test")
    
    pdf_data = ExportService.to_pdf(@user, "reports")
    
    assert pdf_data.is_a?(String)
    assert pdf_data.start_with?("%PDF")
  end

  test "export_projects_pdf generates valid PDF" do
    Project.create!(user_id: @user.id, name: "Test", description: "Test", target_date: Time.zone.today + 30.days)
    
    pdf_data = ExportService.to_pdf(@user, "projects")
    
    assert pdf_data.is_a?(String)
    assert pdf_data.start_with?("%PDF")
  end

  test "export_habits_pdf generates valid PDF" do
    Habit.create!(user_id: @user.id, name: "Exercise")
    
    pdf_data = ExportService.to_pdf(@user, "habits")
    
    assert pdf_data.is_a?(String)
    assert pdf_data.start_with?("%PDF")
  end

  # Error handling
  test "raises error for unsupported model" do
    assert_raises(ArgumentError) do
      ExportService.to_csv(@user, "invalid_model")
    end
  end

  # User isolation
  test "export only returns current user's data" do
    other_user = User.create!(email_address: "other@test.com", password: "password123", password_confirmation: "password123")
    Transaction.create!(user_id: @user.id, description: "User1", category: "Food", amount: 50.00, date: Time.zone.today, transaction_type: "expense")
    Transaction.create!(user_id: other_user.id, description: "User2", category: "Food", amount: 75.00, date: Time.zone.today, transaction_type: "expense")
    
    csv_data = ExportService.to_csv(@user, "transactions")
    csv = CSV.parse(csv_data, headers: true)
    
    assert csv.count == 1
    assert csv.first["Descripcion"] == "User1"
  end

  test "export empty dataset returns headers only" do
    csv_data = ExportService.to_csv(@user, "transactions")
    csv = CSV.parse(csv_data, headers: true)
    
    assert csv.count == 0
    assert csv.headers.include?("Fecha")
  end
end
