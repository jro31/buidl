require 'json'
require 'open-uri'

class Profile < ApplicationRecord

  mount_uploader :photo, PhotoUploader

  belongs_to :user, optional: true

  has_many :leaders, class_name: "UserFollow", foreign_key: "follower_id", dependent: :destroy
  has_many :followers, class_name: "UserFollow", foreign_key: "leader_id", dependent: :destroy

  has_many :profile_technologies, dependent: :destroy
  has_many :technologies, through: :profile_technologies

  has_many :project_follows, dependent: :destroy
  has_many :followed_projects, through: :project_follows, source: "Project"

  has_many :contributions, dependent: :destroy
  has_many :projects, -> { distinct }, through: :contributions

  # self.contributions.map { |contr| contr.project }


  after_create :fetch_github

  def activity
    hash = {}
    self.projects.each do |project|
      hash.store(project.name, {})
      self.contributions.each do |contribution|
        if contribution.project_id == project.id
          hash[project.name].store(contribution.date, contribution.commits)
        end
      end
    end
    hash
  end

  # Show total contribution for a specific project
  def project_contribution_sum(project_id)
    total_commits = 0
    total_lines_added = 0
    total_lines_deleted = 0
    # Loop through all contributions of a single project
    self.contributions.where(project_id: project_id).each do |contribution|
      # Add contributions together
      total_commits += contribution.commits
      total_lines_added += contribution.lines_added
      total_lines_deleted += contribution.lines_deleted
    end
    hash = {
      name: Project.find(project_id).name,
      commits: total_commits,
      lines_added: total_lines_added,
      lines_deleted: total_lines_deleted
    }
  end



  def top_languages
    # Calculations for finding the most used programming langugages in all repos owned by a profile
    hash = {}
    self.projects.each do |project|
      project.project_technologies.each do |project_tech|
        size = project_tech.size_bytes
        name = Technology.find(project_tech.technology_id).name
        if hash.has_key?(name)
          hash[name] += size
        else
          hash[name] = size
        end
      end
    end
    hash.sort_by{|_key, value| value}.reverse
  end

  def commits_per_week_in_a_year(year)
      # self.activity works, year works. Javacript might not work
      CommitsPerWeekInYear.new(self.activity, year).run
  end

  def repo_number
    self.projects.length
  end

  # Show total contribution of a profile
  def total_contributions
    # Total number of commits
    total_commits = 0
    # Total number of lines added
    total_lines_added = 0
    # Total number of lines deleted
    total_lines_deleted = 0
    self.contributions.each do |contribution|
      next unless contribution.commits
      total_commits += contribution.commits
      total_lines_added += contribution.lines_added
      total_lines_deleted += contribution.lines_deleted
    end

    hash = {
      commits: total_commits,
      lines_added: total_lines_added,
      lines_deleted: total_lines_deleted
    }
  end

  private

  def fetch_github
    begin
      FetchGithub.new(self)
      self.save
    rescue
      false
    end
  end

end
