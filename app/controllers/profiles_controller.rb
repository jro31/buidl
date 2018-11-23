class ProfilesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:create, :show]


  def create
    if Profile.find_by(github_username: profile_params[:github_username]).present?
      @profile = Profile.find_by(github_username: profile_params[:github_username])
      authorize @profile
      if @profile.user == nil
        get_profile_user_id
      end
      redirect_to profile_path(@profile)
    else
      @profile = Profile.new(profile_params)
      get_profile_user_id
      authorize @profile
      @profile.save!
      redirect_to profile_path(@profile)
    end
  end

  def show
    if params[:search]
      github_username = params[:search][:github_username]
      @profile = Profile.find_by('github_username @@ ?', "%#{github_username}%")
      unless @profile
        redirect_back(fallback_location: root_path)
        flash[:notice] = "Couldnt find anyone by that GitHub username"
      end
    else
      @user = current_user
      @project = Project.new
      @profile = Profile.find(params[:id])
      authorize @project
      @user_follows = UserFollow.all
      # @user_follow_test = UserFollow.where()
      if @profile.user == nil
        get_profile_user_id
      end
      # If the user has 0 projects or something went wrong w/ the API, redirect to root
      unless @profile.projects.any?
        redirect_to root_path
        flash[:alert] = "Something went wrong, please try again"
      end
    end
    authorize @profile ? @profile : Profile
  end

  def update
    @profile = Profile.find(params[:id])
    @profile.update(profile_params)
    authorize @profile

    #example for user controller @profile.user.profile_photo = @profile.photo
    #example for user controller @profile.user.save
    redirect_to profile_path(@profile)
  end

  private

  def profile_params
    params.require(:profile).permit(:github_username, :photo)
  end

  def get_profile_user_id
    users = User.all
    users.each do |u|
      if u.github_username == @profile.github_username
        @profile.user = u
      end
    end
  end

end
