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
        if date.year == @year
          cweek = Date.parse(date.to_s).cweek
          array[cweek] ? array[cweek] += commits : array[cweek] = commits
        end
      end
      @commits_per_week[name]= array
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
    lowest_indeces = []
    @commits_per_week.each do |name, array|
      lowest_indeces << array.index { |x| x > 0 }
    end
    lowest_index = lowest_indeces.sort.first
    (lowest_index..Date.today.cweek).to_a
  end

  def run
    set_initial_commits_per_week
    fit_commits_to_year
    @commits_per_week
  end

end
