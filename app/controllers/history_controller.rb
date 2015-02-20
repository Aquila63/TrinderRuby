class HistoryController < ApplicationController
  before_action :check_authentication

  def list
    @users = @user.sorted_history
    render :template => 'users/list'
  end
end
