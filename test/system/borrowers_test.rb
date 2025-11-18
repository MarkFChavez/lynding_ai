require "application_system_test_case"

class BorrowersTest < ApplicationSystemTestCase
  setup do
    @borrower = borrowers(:one)
  end

  test "visiting the index" do
    visit borrowers_url
    assert_selector "h1", text: "Borrowers"
  end

  test "should create borrower" do
    visit borrowers_url
    click_on "New borrower"

    fill_in "Address", with: @borrower.address
    fill_in "Email", with: @borrower.email
    fill_in "Name", with: @borrower.name
    fill_in "Phone", with: @borrower.phone
    click_on "Create Borrower"

    assert_text "Borrower was successfully created"
    click_on "Back"
  end

  test "should update Borrower" do
    visit borrower_url(@borrower)
    click_on "Edit this borrower", match: :first

    fill_in "Address", with: @borrower.address
    fill_in "Email", with: @borrower.email
    fill_in "Name", with: @borrower.name
    fill_in "Phone", with: @borrower.phone
    click_on "Update Borrower"

    assert_text "Borrower was successfully updated"
    click_on "Back"
  end

  test "should destroy Borrower" do
    visit borrower_url(@borrower)
    accept_confirm { click_on "Destroy this borrower", match: :first }

    assert_text "Borrower was successfully destroyed"
  end
end
