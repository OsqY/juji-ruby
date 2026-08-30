require "test_helper"
require "fileutils"
require "timeout"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  DOWNLOAD_PATH = Rails.root.join("tmp/system-test-downloads").freeze

  FileUtils.mkdir_p(DOWNLOAD_PATH)

  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |options|
    options.add_preference("download.default_directory", DOWNLOAD_PATH.to_s)
    options.add_preference("download.prompt_for_download", false)
    options.add_preference("download.directory_upgrade", true)
    options.add_preference("safebrowsing.enabled", true)
  end

  parallelize(workers: 1)

  Capybara.save_path = Rails.root.join("tmp/screenshots").to_s

  def sign_in_as(user)
    visit new_session_path
    forms = all("form[action='#{session_path}']", visible: :all)
    form = forms.find(&:visible?)
    email = form.find("input[name='email_address']")
    password = form.find("input[name='password']")
    email.set(user.email_address)
    password.set("password")
    form.find("input[type='submit']", visible: true).click
    assert_text "DASHBOARD"
  end

  def clear_downloads
    FileUtils.rm_f(Dir.glob(DOWNLOAD_PATH.join("*")))
  end

  def wait_for(timeout = Capybara.default_max_wait_time)
    Timeout.timeout(timeout) do
      loop do
        return if yield

        sleep 0.05
      end
    end
  end
end
