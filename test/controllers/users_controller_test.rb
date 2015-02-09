require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  test "should get list" do
    get :list
    assert_response :success
  end

  test "should get like" do
    get :like
    assert_response :success
  end

  test "should get ignore" do
    get :ignore
    assert_response :success
  end

  test "should get update" do
    get :update
    assert_response :success
  end

end
