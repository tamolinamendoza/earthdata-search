# EDSC-97 As a user, I want to log in so that I may access my saved 
#         information and retrieve restricted data
# EDSC-98 As a user, I want to see an indication that I am logged in 
#         so I may know the credentials I am currently using
# EDSC-99 As a user, I want to log out so that nobody else may access 
#         my account

require "spec_helper"

describe "Login", reset: false do
  before(:all) do
    Capybara.reset_sessions!
    visit "/search"
  end

  before(:each) do
    click_link 'Login'
    fill_in 'Username', with: 'edsc'
    fill_in 'Password', with: 'EDSCtest!1'
    click_button 'Login'
    wait_for_xhr
  end

  after(:each) do
    reset_user
  end

  it "logs a user in successfully" do
    script = "window.edsc.models.page.current.user.isLoggedIn()"
    response = page.evaluate_script(script)

    expect(response).to eq(true)
  end

  it "display the user information while logged in" do
    within(".toolbar") do
      expect(page).to have_content("edsc")
    end
  end

  it "logs the user out" do
    click_link 'edsc'
    click_link 'Logout'

    script = "window.edsc.models.page.current.user.isLoggedIn()"
    response = page.evaluate_script(script)

    expect(response).to eq(false)
  end
end
