require 'spec_helper'

describe 'users/show.html.erb' do
  let(:user) { FactoryGirl.create :user }

  before do
    assign(:user, user)
    #@ability = Object.new.extend(CanCan::Ability)
    #controller.stub(:current_ability) { @ability }
    controller.stub(:current_user).and_return user
  end

  describe 'A user with access' do
    before do
      #@ability.can :generate_api_key, user
      allow(view).to receive(:policy).and_return double(edit?:true, generate_api_key?: true, destroy?: false)
      render
    end

    it 'displays the API key section' do
      rendered.should have_css('h4', text: 'API Secret Key')
    end

    it 'has a link to generate an API key' do
      rendered.should have_link('Generate API Secret Key', href: generate_api_key_user_path(user))
    end
  end

  describe 'A user without access' do
    before do
      #@ability.cannot :generate_api_key, user
      allow(view).to receive(:policy).and_return double(edit?:false, generate_api_key?: false, destroy?: false)
      render
    end

    it 'does not display the API key section' do
      rendered.should_not have_css('h4', text: 'API Secret Key')
    end

    it 'has a link to generate an API key' do
      rendered.should_not have_link('Generate API Secret Key', href: generate_api_key_user_path(user))
    end
  end

end