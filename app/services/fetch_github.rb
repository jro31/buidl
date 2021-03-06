require 'date'
class FetchGithub
  def initialize(profile)
    @profile = profile
    @key = ENV['GITHUB_TOKEN']
    @projects = []
    @github_username = profile.github_username
    fetch_github
  end

  def fetch_repo_commits(projects)
    projects.each do |repo|
      repo_contributions_serialized = open("https://api.github.com/repos/#{@github_username}/#{repo.name}/stats/contributors?access_token=#{@key}").read
      if repo_contributions_serialized == ""
        # If API call retries an empty string, create empty contribution to link project to profile
        Contribution.new(profile_id: @profile.id, project_id: repo.id).save!
      else
        repo_contributions = JSON.parse(repo_contributions_serialized)
        store_contribution_data(repo_contributions, repo)
      end
    end
  end

  def store_contribution_data(repo_contributions, repo)
    repo = repo
    # Loop over all contributions of a single repository
    repo_contributions.each do |contributions|
      if contributions['author']['login'] == @github_username
        # Loop over all contrubutions of a single contributor
        contributions['weeks'].each do |contribution|
          lines_added = contribution['a'].to_i
          lines_deleted = contribution['d'].to_i
          commits = contribution['c'].to_i
          datetime = Time.at(contribution['w']).to_datetime
          # Call Create function
          create_contributions(lines_added, lines_deleted, commits, repo, datetime)
        end
      end
    end
  end

  def create_contributions(lines_added, lines_deleted, commits, repo, datetime)
    new_contribution = Contribution.new(lines_added: lines_added, lines_deleted: lines_deleted, commits: commits, profile_id: @profile.id, project_id: repo.id, date: datetime)
    new_contribution.save!
  end

  def fetch_and_parse(url)
    data_serialized = open(url).read
    JSON.parse(data_serialized)
  end

  def set_profile(github_profile)
    @profile.profile_photo = github_profile['avatar_url']
    @profile.github_url = github_profile['html_url']
    @profile.description = github_profile['bio']
    @profile.full_name = github_profile['name']
    @profile.github_username = github_profile['login']
    @github_username = @profile.github_username

  end

  def set_project(repo)
    Project.new(
      name: repo['name'],
      private: repo['private'],
      github_description: repo['description'],
      primary_language: repo['language'],
      size_kilobytes: repo['size'],
      github_url: repo['html_url'],
      url: repo['homepage'],
      owner_id: repo['owner']['id'],
      github_id: repo['id']
    )
  end

  def fetch_projects(github_repos)
    # Iterate over first 25 repos of a github account
    github_repos.first(25).each do |repo|
      # Create Project Instance
      project = set_project(repo)
      project.save!
      # Store project in temporary projects array
      @projects << project
      # Find all technologies of a project
      project_techs = fetch_and_parse("https://api.github.com/repos/#{@github_username}/#{project.name}/languages?access_token=#{@key}")
      set_project_techs(project_techs, project)
    end
  end

  def set_project_techs(techs, project)
    techs.each do |tech|
      lang = tech.first.downcase
      size_bytes = tech.last
      unless Technology.find_by(name: lang).nil?
        proj_tech = ProjectTechnology.new(project_id: project.id, technology_id: Technology.find_by(name: lang).id, size_bytes: size_bytes).save!
      end
    end
  end

  def fetch_github
    # begin
    github_profile = fetch_and_parse("https://api.github.com/users/#{@github_username}?access_token=#{@key}")
    # rescue OpenURI::HTTPError
      # return @profile.errors.add(:github_username, "Does not exist!")
    # end
    set_profile(github_profile)
    github_repos = fetch_and_parse("https://api.github.com/users/#{@github_username}/repos?access_token=#{@key}")
    fetch_projects(github_repos)
    fetch_repo_commits(@projects)
  end

end
