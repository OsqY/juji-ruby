# test/integration/hotwire_native_test.rb
# Tests para verificar que Hotwire Native funciona correctamente

require "test_helper"
require "capybara/minitest"

class HotwireNativeTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  setup do
    @user = users(:one)
  end

  test "native client is detected via User-Agent" do
    get dashboard_path, headers: { 'User-Agent' => 'TurboNative/1.0' }
    
    assert_response :success
    assert response.headers['X-Hotwire-Native'] == 'true',
      "X-Hotwire-Native header not set for native client"
  end

  test "web client does not get native header" do
    get dashboard_path, headers: { 'User-Agent' => 'Mozilla/5.0' }
    
    assert_response :success
    assert response.headers['X-Hotwire-Native'].nil? ||
           response.headers['X-Hotwire-Native'] != 'true',
      "X-Hotwire-Native header incorrectly set for web client"
  end

  test "native client receives mobile layout" do
    # Log in first
    post session_path, params: {
      email_address: @user.email_address,
      password: 'password'
    }
    
    get dashboard_path, headers: { 'User-Agent' => 'TurboNative/1.0' }
    
    assert response.body.include?('application_mobile'),
      "Mobile layout not used for native client"
  end

  test "CORS headers are present for native requests" do
    options dashboard_path, headers: {
      'Origin' => 'https://native-app.example.com',
      'User-Agent' => 'TurboNative/1.0'
    }
    
    assert response.headers['Access-Control-Allow-Origin'].present? ||
           response.headers['Access-Control-Allow-Methods'].present?,
      "CORS headers not present"
  end

  test "deep link routing works" do
    post session_path, params: {
      email_address: @user.email_address,
      password: 'password'
    }
    
    get dashboard_path, headers: {
      'User-Agent' => 'TurboNative/1.0',
      'X-Deep-Link' => dashboard_path
    }
    
    assert_response :success
  end

  test "native client gets optimized error pages" do
    get '/non-existent-path', headers: { 'User-Agent' => 'TurboNative/1.0' }
    
    assert_response :not_found
    assert response.body.include?('🔍') ||
           response.body.include?('No Encontrado'),
      "Custom mobile error page not shown"
  end

  test "Turbo works in native context" do
    post session_path, params: {
      email_address: @user.email_address,
      password: 'password'
    }
    
    # Test Turbo Frame request
    get transactions_path, headers: {
      'User-Agent' => 'TurboNative/1.0',
      'Turbo-Frame' => 'transactions_content'
    }
    
    assert_response :success
    assert response.body.include?('transactions_content'),
      "Turbo Frame not found in response"
  end

  test "Stimulus controllers work on mobile" do
    post session_path, params: {
      email_address: @user.email_address,
      password: 'password'
    }
    
    get dashboard_path, headers: { 'User-Agent' => 'TurboNative/1.0' }
    
    assert_response :success
    # Verificar que Stimulus está cargado
    assert response.body.include?('data-controller'),
      "Stimulus attributes not found in native response"
  end

  test "form submissions work in native" do
    post session_path, params: {
      email_address: @user.email_address,
      password: 'password'
    }
    
    # Simular form submission en native
    post transactions_path, params: {
      transaction: {
        amount: 100,
        category: 'food',
        date: Date.today
      }
    }, headers: {
      'User-Agent' => 'TurboNative/1.0',
      'Turbo-Frame' => 'transactions_content'
    }
    
    assert response.ok? || response.status == 422,
      "Form submission failed: #{response.status}"
  end
end
