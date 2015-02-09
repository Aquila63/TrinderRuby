class HistoryController < ApplicationController
  before_action :check_authentication

  def list
    ids = @user.history.to_a
    @users = User.where(id:ids).order("field(id, '#{ids.join(',')}')").offset(params[:offset]).limit(params[:limit])
    render :template => 'users/list'
  end
end
