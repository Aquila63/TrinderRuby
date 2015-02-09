class UsersController < ApplicationController

  before_action :check_authentication

  def list
    @users = @user.random_valid_users(30)
  end

  def like
    other_user = User.find(params[:id])
    return unless other_user

    @user.like other_user
    render json: {success:true}, status: 200
  end

  def ignore
    @user.history << params[:id]
    render json: {success:true}, status: 200
  end


  def update
    # todo
  end
end
