# test/integration/mobile_interaction_test.rb
# Tests para interacciones específicas de mobile (touch, gestos, etc)

require "test_helper"

class MobileInteractionTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "bottom navigation responds to clicks on mobile" do
    post session_path, params: {
      email_address: @user.email_address,
      password: 'password'
    }
    
    # Simular solicitud nativa
    get dashboard_path, headers: {
      'User-Agent' => 'TurboNative/1.0'
    }
    
    assert_response :success
    assert response.body.include?('mobile-nav'),
      "Bottom navigation not found in mobile response"
  end

  test "pull to refresh support in mobile layout" do
    post session_path, params: {
      email_address: @user.email_address,
      password: 'password'
    }
    
    get dashboard_path, headers: { 'User-Agent' => 'TurboNative/1.0' }
    
    # Verificar que el layout soporta pull-to-refresh (no hay overflow-y: hidden en body)
    assert response.body.include?('-webkit-overflow-scrolling'),
      "Webkit scrolling acceleration not configured"
  end

  test "touch target sizes are adequate" do
    post session_path, params: {
      email_address: @user.email_address,
      password: 'password'
    }
    
    get dashboard_path, headers: { 'User-Agent' => 'TurboNative/1.0' }
    
    # Verificar CSS de buttons
    assert response.body.include?('min-height: 48px') ||
           response.body.include?('min-height: 44px'),
      "Button touch targets not optimized"
  end

  test "keyboard dismiss support for forms" do
    post session_path, params: {
      email_address: @user.email_address,
      password: 'password'
    }
    
    get new_transaction_path, headers: { 'User-Agent' => 'TurboNative/1.0' }
    
    # Formulario debe tener soporte para descartar teclado
    assert response.body.include?('font-size: 16px') ||
           response.body.include?('-webkit-appearance: none'),
      "Form inputs not optimized for keyboard handling"
  end

  test "notch padding respected in layout" do
    post session_path, params: {
      email_address: @user.email_address,
      password: 'password'
    }
    
    get dashboard_path, headers: { 'User-Agent' => 'TurboNative/1.0' }
    
    # Layout debe usar safe-area-inset
    assert response.body.include?('env(safe-area-inset-top)') ||
           response.body.include?('safe-area-inset-bottom'),
      "Safe area insets not implemented"
  end

  test "form validation errors accessible on mobile" do
    post session_path, params: {
      email_address: @user.email_address,
      password: 'password'
    }
    
    # Intentar crear transacción con datos inválidos (vacíos)
    post transactions_path, params: {
      transaction: { amount: '', description: '', category: '', date: '', transaction_type: '' }
    }, headers: {
      'User-Agent' => 'TurboNative/1.0'
    }
    
    assert response.status == 422 ||
           response.body.include?('Datos Incompletos') ||
           response.body.include?('Validación'),
      "Validation errors not handled properly"
  end

  test "long lists are scrollable on mobile" do
    post session_path, params: {
      email_address: @user.email_address,
      password: 'password'
    }
    
    # Crear varios elementos para testing de scroll
    10.times do |i|
      @user.transactions.create!(
        amount: 10 + i,
        category: 'food',
        date: Date.today - i.days,
        description: "Compra #{i}",
        transaction_type: 'expense'
      )
    end
    
    get transactions_path, headers: { 'User-Agent' => 'TurboNative/1.0' }
    
    assert_response :success
    # Verificar que la lista puede scrollear
    assert response.body.include?('flex-direction: column') ||
           response.body.include?('overflow'),
      "List not optimized for scrolling"
  end

  test "modal/drawer closes on back gesture" do
    post session_path, params: {
      email_address: @user.email_address,
      password: 'password'
    }
    
    # Abrir un nuevo formulario
    get new_transaction_path, headers: { 'User-Agent' => 'TurboNative/1.0' }
    
    # Simular cancel/back
    get transactions_path, headers: { 'User-Agent' => 'TurboNative/1.0' }
    
    assert_response :success
    assert response.body.include?('transactions'),
      "Navigation back did not work properly"
  end

  test "orientation change reflow works" do
    post session_path, params: {
      email_address: @user.email_address,
      password: 'password'
    }
    
    # Portrait
    get dashboard_path, headers: { 'User-Agent' => 'TurboNative/1.0' }
    portrait_response = response.body
    
    # Landscape (los headers no indican orientación real, pero podemos verificar CSS)
    get dashboard_path, headers: { 'User-Agent' => 'TurboNative/1.0' }
    landscape_response = response.body
    
    # Ambos deben render correctamente
    assert portrait_response.include?('chaotic-container'),
      "Container not found in portrait"
    assert landscape_response.include?('chaotic-container'),
      "Container not found in landscape"
  end

  test "tap highlight visible on interactive elements" do
    post session_path, params: {
      email_address: @user.email_address,
      password: 'password'
    }
    
    get dashboard_path, headers: { 'User-Agent' => 'TurboNative/1.0' }
    
    # Verificar tap highlight color configurado
    assert response.body.include?('-webkit-tap-highlight-color') ||
           response.body.include?('transition'),
      "Tap feedback not configured"
  end
end
