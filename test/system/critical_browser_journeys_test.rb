require "application_system_test_case"

class CriticalBrowserJourneysTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @other_user = users(:two)
  end

  test "authentication, session expiry, and authorization are observable in a browser" do
    sign_in_as(@user)

    other_transaction = @other_user.transactions.create!(
      amount: 999,
      description: "Private transaction",
      transaction_type: :expense,
      category: "private",
      date: Date.current
    )

    page.driver.browser.manage.delete_all_cookies
    visit notifications_path
    assert_current_path new_session_path

    visit new_session_path
    sign_in_as(@user)
    visit transaction_path(other_transaction)
    assert_text "Not Found"
  end

  test "daily reports and transactions show reproducible browser evidence" do
    sign_in_as(@user)

    visit new_daily_report_path
    report_form = find("form[action='/daily_reports']", visible: true)
    within(report_form) do
      fill_in "daily_report_work_title", with: "Browser report"
      fill_in "daily_report_worked_by", with: "QA"
      fill_in "daily_report_yesterday", with: "Checked the browser flow"
      fill_in "daily_report_today", with: "Keep the journey reproducible"
      fill_in "daily_report_blockers", with: ""
      find("input[type='submit']").click
    end
    assert_text(/Browser report/i)
    report = @user.daily_reports.find_by!(work_title: "Browser report")
    assert_css "a[href='#{edit_daily_report_path(report)}']"

    visit new_transaction_path
    fill_in "transaction_amount", with: "42.50"
    fill_in "transaction_description", with: "Browser purchase"
    find("input[name='transaction[category_custom]']").set("qa")
    find("form[action='/transactions'] input[type='submit']").click
    assert_text(/Browser purchase/i)
    assert Transaction.exists?(user: @user, description: "Browser purchase")
  end

  test "projects, tasks, habits, shopping, and goals expose their browser actions" do
    project = @user.projects.create!(name: "Browser project", description: "Journey")
    project.project_tasks.create!(name: "Browser task")
    habit = @user.habits.create!(name: "Browser habit")
    @user.shopping_items.create!(name: "Browser item", quantity: "1")
    goal = @user.monthly_goals.create!(
      title: "Browser goal",
      target_value: 100,
      month: Date.current.beginning_of_month,
      goal_type: :savings,
      category: "qa"
    )

    sign_in_as(@user)

    visit projects_path
    assert_text(/#{Regexp.escape(project.name)}/i)
    assert_text(/#{Regexp.escape(project.project_tasks.first.name)}/i)
    assert_css "form[action='#{project_project_tasks_path(project)}']"

    visit habits_path
    assert_text(/#{Regexp.escape(habit.name)}/i)
    assert_css "form[action='#{habits_path}']"

    visit shopping_items_path
    assert_text(/Browser item/i)
    assert_css "form[action='#{shopping_items_path}']"

    visit monthly_goals_path
    assert_text(/#{Regexp.escape(goal.title)}/i)
    assert_css "form[action='#{check_progress_monthly_goal_path(goal)}']"
  end

  test "budgets, exports, and notifications have visible controls and state changes" do
    transaction = @user.transactions.create!(
      amount: 12,
      description: "Exportable purchase",
      transaction_type: :expense,
      category: "qa",
      date: Date.current
    )
    notification = @user.notifications.create!(
      notification_type: :budget_exceeded,
      message: "Browser notification"
    )

    sign_in_as(@user)

    visit budgets_path
    budget_form = find("form[action^='/budgets']", visible: true)
    within(budget_form) do
      find("input[name='budget[category_custom]']").set("browser")
      fill_in "budget_monthly_limit", with: "75"
      find("input[type='submit']").click
    end
    assert_text(/BROWSER/i)
    assert_text(/75\.00/)
    assert Budget.exists?(user: @user, category: "browser", monthly_limit: 75)

    clear_downloads
    visit transactions_path
    assert_text(/#{Regexp.escape(transaction.description)}/i)
    assert_button "EXPORTAR CSV"
    export_form = all("form[action^='/exports'][data-turbo='false']", visible: true).first
    within(export_form) { click_button "EXPORTAR CSV" }
    wait_for { Dir.glob(DOWNLOAD_PATH.join("transactions_*.csv")).any? }
    csv = File.read(Dir.glob(DOWNLOAD_PATH.join("transactions_*.csv")).first)
    assert_includes csv, transaction.description

    visit notifications_path
    assert_text notification.message
    find("form[action='#{mark_as_read_notification_path(notification)}']").click_button "OK"
    visit notifications_path
    assert_no_css "form[action='#{mark_as_read_notification_path(notification)}']"
  end

  test "public forms and invitations prove their success and isolation paths" do
    form = @user.anonymous_forms.create!(
      title: "Browser public form",
      response_limit: 2,
      questions_attributes: {
        "0" => {
          prompt: "What did you verify?",
          question_type: :free_text,
          required: true,
          position: 0
        }
      }
    )

    visit public_anonymous_form_path(form.token)
    assert_text(/#{Regexp.escape(form.title)}/i)
    fill_in "answers_#{form.questions.first.id}", with: "The public journey"
    click_button "ENVIAR RESPUESTA"
    assert_text(/Respuesta enviada/i)
    assert_equal 1, form.reload.responses_count

    sign_in_as(@user)
    visit user_invite_path(token: @other_user.invite_token)
    assert_current_path friends_path
    assert @user.friendship_with(@other_user).pending?
  end

  test "chat and whiteboard expose realtime browser wiring" do
    room = @user.chat_rooms.create!(name: "Browser chat", room_type: :open)
    room.add_member(@user, role: :owner)
    room.messages.create!(user: @user, content: "Persisted realtime message")
    whiteboard = @user.whiteboards.create!(name: "Browser board")

    sign_in_as(@user)

    using_session(:observer) do
      sign_in_as(@user)
      visit chat_room_path(room)
      assert_text "Persisted realtime message"
      wait_for { page.evaluate_script("Array.from(document.querySelectorAll('[data-controller]')).some((element) => element.dataset.controller?.includes('chat-room') && element.dataset.chatRoomConnected === 'true')") }
    end

    visit chat_room_path(room)
    assert_text(/#{Regexp.escape(room.name)}/i)
    assert_text "Persisted realtime message"
    assert_css "#messages[data-chat-room-target='messages'][aria-live='polite']"
    wait_for { page.evaluate_script("Array.from(document.querySelectorAll('[data-controller]')).some((element) => element.dataset.controller?.includes('chat-room') && element.dataset.chatRoomConnected === 'true')") }
    message_form = find("form[action='#{chat_room_messages_path(room)}']", visible: true)
    chat_root = message_form.find(:xpath, "./ancestor::*[contains(concat(' ', normalize-space(@data-controller), ' '), ' chat-room ')][1]")
    wait_for { chat_root["data-chat-room-connected"] == "true" }
    within(message_form) do
      find("input[name='message[content]']").set("Browser realtime message")
    end
    message_form.find("input[type='submit']", visible: true).click
    using_session(:observer) do
      assert_text(/Browser realtime message/i)
    end

    using_session(:observer) do
      visit whiteboard_path(whiteboard)
      assert_text "Conectado."
      page.execute_script(<<~JS)
        window.__remoteStrokeCount = 0
        const originalStroke = CanvasRenderingContext2D.prototype.stroke
        CanvasRenderingContext2D.prototype.stroke = function(...args) {
          window.__remoteStrokeCount += 1
          return originalStroke.apply(this, args)
        }
      JS
    end

    visit whiteboard_path(whiteboard)
    assert_css "[data-controller~='whiteboard'] canvas[role='application']"
    assert_css "[data-whiteboard-token-value='#{whiteboard.token}']"
    assert_text "Conectado."
    canvas = all("canvas[data-whiteboard-target='canvas']", visible: true).first
    page.execute_script(<<~JS, canvas.native)
      const canvas = arguments[0]
      const event = (type, x, y) => canvas.dispatchEvent(new MouseEvent(type, {
        bubbles: true,
        button: 0,
        clientX: x,
        clientY: y
      }))
      event("mousedown", 20, 20)
      event("mousemove", 80, 80)
      event("mouseup", 80, 80)
    JS
    wait_for { WhiteboardStroke.exists?(whiteboard: whiteboard) }
    using_session(:observer) do
      wait_for { page.evaluate_script("window.__remoteStrokeCount") > 0 }
    end
  end
end
