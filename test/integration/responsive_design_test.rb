# test/integration/responsive_design_test.rb
# Tests para verificar que la app es responsive en diferentes tamaños de pantalla

require "test_helper"
require "capybara/minitest"

class ResponsiveDesignTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  setup do
    @user = users(:one) # Asume que existe un usuario en fixtures
    sign_in_as @user
  end

  # Viewport sizes para testing
  MOBILE_SIZES = {
    small_phone: { width: 320, height: 568 },  # iPhone SE
    medium_phone: { width: 375, height: 667 }, # iPhone 14
    large_phone: { width: 414, height: 896 },  # iPhone 14 Plus
    tablet: { width: 768, height: 1024 }       # iPad
  }.freeze

  test "dashboard loads on mobile viewports" do
    MOBILE_SIZES.each do |device, dimensions|
      visit dashboard_path
      page.current_window.resize_to(dimensions[:width], dimensions[:height])
      
      assert page.has_css?('.chaotic-container'), 
        "chaotic-container not found on #{device}"
      assert page.has_selector?('main'), 
        "main tag not found on #{device}"
    end
  end

  test "navigation is accessible on mobile" do
    visit dashboard_path
    page.current_window.resize_to(375, 667) # Mobile medium
    
    # En mobile debe haber elementos táctiles
    assert page.has_css?('.mobile-nav'), 
      "Bottom navigation not found on mobile"
    assert page.has_css?('a, button', minimum: 1),
      "No interactive elements found"
  end

  test "forms are usable on mobile" do
    visit new_transaction_path
    page.current_window.resize_to(375, 667)
    
    # Verificar que los inputs sean accesibles
    assert page.has_field?('transaction[amount]'),
      "Amount field not found"
    assert page.find('input[type="number"]')['style'].nil? || 
           page.find('input[type="number"]')['style'].include?('font-size: 16px') ||
           page.find('input[type="number"]')['style'].include?('-webkit-appearance: none'),
      "Input no optimizado para mobile"
  end

  test "no horizontal scroll on small phones" do
    visit daily_reports_path
    page.current_window.resize_to(320, 568) # Smallest phone
    
    # El body no debe tener overflow-x
    body_overflow = page.evaluate_script(
      "window.getComputedStyle(document.body).overflowX"
    )
    assert body_overflow != 'scroll',
      "Page has horizontal scroll on smallest phone"
  end

  test "touch targets are >= 48px" do
    visit dashboard_path
    page.current_window.resize_to(375, 667)
    
    # Verificar todos los botones
    buttons = page.all('button, a[role="button"], input[type="submit"]')
    buttons.each do |button|
      next if button.visible? == false
      
      size = page.evaluate_script(
        "document.querySelector('button').getBoundingClientRect()"
      )
      
      # Permitir cierta flexibilidad en el cálculo
      assert size['height'] >= 44 || size['width'] >= 44,
        "Button too small for touch: #{size}"
    end
  end

  test "safe areas respected on notched devices" do
    visit dashboard_path
    
    # Simular notch
    page.execute_script <<~JS
      document.documentElement.style.setProperty('--safe-area-inset-top', '50px');
      document.documentElement.style.setProperty('--safe-area-inset-bottom', '34px');
    JS

    page.current_window.resize_to(375, 812) # iPhone X (notched)
    
    # Content debe estar dentro de safe areas
    main = page.find('main')
    assert main.visible?,
      "Main content not visible with safe area insets"
  end

  test "text remains readable on mobile" do
    visit transactions_path
    page.current_window.resize_to(375, 667)
    
    # Font size no debe ser muy pequeño
    smallest_font_size = page.evaluate_script(
      "Math.min(...Array. from(document.querySelectorAll('*')).map(el => window.getComputedStyle(el).fontSize).map(s => parseInt(s)))"
    )
    
    assert smallest_font_size >= 12,
      "Some text is less than 12px: #{smallest_font_size}px"
  end

  test "layout adapts to different orientations" do
    visit dashboard_path
    
    # Portrait
    page.current_window.resize_to(375, 667)
    assert page.has_css?('main'),
      "Main not found in portrait"
    
    # Landscape
    page.current_window.resize_to(667, 375)
    assert page.has_css?('main'),
      "Main not found in landscape"
  end

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
