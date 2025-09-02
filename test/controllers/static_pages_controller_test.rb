require "test_helper"

class StaticPagesControllerTest < ActionDispatch::IntegrationTest
  test "should get root" do
    get static_pages_root_url
    assert_response :success
  end

  test "should get somos" do
    get static_pages_somos_url
    assert_response :success
  end

  test "should get tech" do
    get static_pages_tech_url
    assert_response :success
  end
end
