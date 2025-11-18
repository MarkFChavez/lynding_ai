require "application_system_test_case"

class ReferralAgentsTest < ApplicationSystemTestCase
  setup do
    @referral_agent = referral_agents(:one)
  end

  test "visiting the index" do
    visit referral_agents_url
    assert_selector "h1", text: "Referral agents"
  end

  test "should create referral agent" do
    visit referral_agents_url
    click_on "New referral agent"

    fill_in "Commission rate", with: @referral_agent.commission_rate
    fill_in "Email", with: @referral_agent.email
    fill_in "Name", with: @referral_agent.name
    fill_in "Phone", with: @referral_agent.phone
    click_on "Create Referral agent"

    assert_text "Referral agent was successfully created"
    click_on "Back"
  end

  test "should update Referral agent" do
    visit referral_agent_url(@referral_agent)
    click_on "Edit this referral agent", match: :first

    fill_in "Commission rate", with: @referral_agent.commission_rate
    fill_in "Email", with: @referral_agent.email
    fill_in "Name", with: @referral_agent.name
    fill_in "Phone", with: @referral_agent.phone
    click_on "Update Referral agent"

    assert_text "Referral agent was successfully updated"
    click_on "Back"
  end

  test "should destroy Referral agent" do
    visit referral_agent_url(@referral_agent)
    accept_confirm { click_on "Destroy this referral agent", match: :first }

    assert_text "Referral agent was successfully destroyed"
  end
end
