require "test_helper"

class ReferralAgentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @referral_agent = referral_agents(:one)
  end

  test "should get index" do
    get referral_agents_url
    assert_response :success
  end

  test "should get new" do
    get new_referral_agent_url
    assert_response :success
  end

  test "should create referral_agent" do
    assert_difference("ReferralAgent.count") do
      post referral_agents_url, params: { referral_agent: { commission_rate: @referral_agent.commission_rate, email: @referral_agent.email, name: @referral_agent.name, phone: @referral_agent.phone } }
    end

    assert_redirected_to referral_agent_url(ReferralAgent.last)
  end

  test "should show referral_agent" do
    get referral_agent_url(@referral_agent)
    assert_response :success
  end

  test "should get edit" do
    get edit_referral_agent_url(@referral_agent)
    assert_response :success
  end

  test "should update referral_agent" do
    patch referral_agent_url(@referral_agent), params: { referral_agent: { commission_rate: @referral_agent.commission_rate, email: @referral_agent.email, name: @referral_agent.name, phone: @referral_agent.phone } }
    assert_redirected_to referral_agent_url(@referral_agent)
  end

  test "should destroy referral_agent" do
    assert_difference("ReferralAgent.count", -1) do
      delete referral_agent_url(@referral_agent)
    end

    assert_redirected_to referral_agents_url
  end
end
