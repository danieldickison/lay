require 'test_helper'

class TablettesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get tablettes_index_url
    assert_response :success
  end

end
