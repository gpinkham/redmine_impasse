class ImpasseRequirementIssuesController < ImpasseAbstractController
  unloadable

  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper
  include IssuesHelper

  def index
    @project = Project.find(params[:project_id])
    setting = Impasse::Setting.find_by_project_id(@project.id)
    params[:set_filter] = true
    params[:fields] ||= []
    params[:fields] << 'tracker_id'
    params[:values] ||= {}
    params[:values][:tracker_id] = setting.requirement_tracker.select{|e| e != ""}
    params[:operators] ||= {}
    params[:operators][:tracker_id] = "="

    retrieve_query
    sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)

    if @query.valid?
      @limit = per_page_option

      @issue_count = @query.issue_count
      @issue_pages = Paginator.new self, @issue_count, @limit, params['page']
      @offset ||= @issue_pages.current.offset
      @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                              :order => sort_clause,
                              :offset => @offset,
                              :limit => @limit)
      @issue_count_by_group = @query.issue_count_by_group

      render :index, :layout => !request.xhr?
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def traceability_report
    @project = Project.find(params[:project_id])
    retrieve_query
    sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)

    logger.error @query.inspect

    if @query.valid?
      case params[:format]
        when 'csv'
          @limit = Setting.issues_export_limit.to_i
        else
          @limit = per_page_option
      end

      @issue_count = @query.issue_count
      @issue_pages = Paginator.new self, @issue_count, @limit, params['page']
      @offset ||= @issue_pages.current.offset
      @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                              :order => sort_clause,
                              :offset => @offset,
                              :limit => @limit)
      @issue_count_by_group = @query.issue_count_by_group
      @issues_with_tests = []
      if params[:format] == 'csv'
        @issues_with_tests << 'Requirement #,User Requirement,Test Case,Step,Procedure,Expected Result,Actual Result, Pass/Fail,Initial/Date'
        @issues.each do |issue|
          if issue.test_cases.present?
            issue.test_cases.each_with_index do |tc, index|
              tc.test_steps.each_with_index do |ts, ts_index|
                if (index == 0 && ts_index == 0)
                  @issues_with_tests << "#{issue.id},\"#{issue.description.gsub('"','\""')}\",\"#{tc.id}: #{tc.node.name.gsub('"','\""')}\",#{ts.step_number},\"#{ts.actions.gsub('"','\""')}\",\"#{ts.expected_results.gsub('"','\""')}\",,,"
                else
                  if (ts_index == 0)
                    @issues_with_tests << ",,\"#{tc.id}: #{tc.node.name.gsub('"','\""')}\",#{ts.step_number},\"#{ts.actions.gsub('"','\""')}\",\"#{ts.expected_results.gsub('"','\""')}\",,,"
                  else
                    @issues_with_tests << ",,,#{ts.step_number},\"#{ts.actions.gsub('"','\""')}\",\"#{ts.expected_results.gsub('"','\""')}\",,,"
                  end
                end
              end
            end
          else
            @issues_with_tests << "#{issue.id},\"#{issue.description.gsub('"','\""')}\",Not Assigned,,,,,,"
          end
        end
      end

      respond_to do |format|
        format.html
        format.csv { send_data(@issues_with_tests.join("\n"), :type => 'text/csv; header=present', :filename => 'traceability_report.csv') }
      end
    end

  end

  def add_test_case
    ActiveRecord::Base.transaction do
      requirement_issue = Impasse::RequirementIssue.find_by_issue_id(params[:issue_id]) ||
          Impasse::RequirementIssue.create(:issue_id => params[:issue_id])
      node = Impasse::Node.find(params[:test_case_id])
      if node.is_test_case?
        create_requirement_case(requirement_issue.id, node.id)
      else
        for test_case_node in node.all_decendant_cases
          create_requirement_case(requirement_issue.id, test_case_node.id)
        end
      end

      render :json => { :status => 'success', :message => l(:notice_successful_create) }
    end
  end

  def remove_test_case
    ActiveRecord::Base.transaction do
      requirement_issue = Impasse::RequirementIssue.find(params[:id])
      requirement_cases = requirement_issue.requirement_cases.find(:first, :conditions => { :test_case_id => params[:test_case_id] })
      requirement_cases.destroy

      render :json => { :status => 'success', :message => l(:notice_successful_delete) }
    end
  end

  private
  def create_requirement_case(requirement_id, test_case_id) 
    Impasse::RequirementCase.find_by_requirement_id_and_test_case_id(requirement_id, test_case_id) || Impasse::RequirementCase.create(:requirement_id => requirement_id, :test_case_id => test_case_id)
  end

end

