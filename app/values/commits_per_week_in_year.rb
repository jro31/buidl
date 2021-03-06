class CommitsPerWeekInYear
  def initialize(activity, year)
    @year = year
    @activity = activity
    @commits_per_week = Hash.new(0)
  end

  def nil.>(arg)
    # monkey patch nil value comparison return for creating year array
    0 > arg
  end

  def set_initial_commits_per_week
    @activity.each do |name, value|
      array = []
      value.each do |date, commits|
        # If there is no date, dont do it
        next unless date
        # Check if year of commit was in 2018, if not, skip
        if date.year == @year
          cweek = Date.parse(date.to_s).cweek
          array[cweek] ? array[cweek] += commits : array[cweek] = commits
        end
      end
      # If this is 0, it basically means no commits have been made for the chose repositories in 2018
      if array == []
        @commits_per_week[name] = [0]
      else
        @commits_per_week[name] = array
      end
    end
  end

  def fit_commits_to_year
    year_array = create_year_array
    @commits_per_week.each do |key, value|
      @commits_per_week[key] = year_array.map do |cweek|
        value[cweek] ? value[cweek] : 0
      end
    end
    @commits_per_week[:year_array] = year_array
  end

  def create_year_array
    lowest_indices = []
    @commits_per_week.each do |name, array|
      result = array.index { |x| x > 0 }
      lowest_indices << result if result != nil
    end
    # return [] if lowest_indices.empty?
    # If nil values are present, take first non nil value
    # Temporary fix
    # non_nil = lowest_indices.select{|i| i != nil}
    # lowest_index = non_nil.sort.first
    lowest_index = lowest_indices.sort.first
    (lowest_index..Date.today.cweek).to_a
  end

  def run
    begin
      set_initial_commits_per_week
      fit_commits_to_year
      @commits_per_week
    rescue
      {"no commits in 2018"=>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], :year_array=>[32, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47]}
    end
  end
end

