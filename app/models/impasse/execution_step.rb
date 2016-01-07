module Impasse
  class ExecutionStep < ActiveRecord::Base
    unloadable
    self.table_name = "impasse_execution_steps"
    self.include_root_in_json = false

    belongs_to :impasse_execution
    belongs_to :test_step
    has_many :issues, :through => :execution_bugs
    has_many :execution_bugs

    acts_as_customizable
  end
end
