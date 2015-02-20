class MatchesController < ApplicationController
  before_action :check_authentication

  def list
    @users = @user.sorted_matches
    render :template => 'users/list'
  end
end
