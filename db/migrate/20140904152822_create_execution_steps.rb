class CreateExecutionSteps < ActiveRecord::Migration
  def self.up
    create_table :impasse_execution_steps do |t|
      t.belongs_to :impasse_executions
      t.belongs_to :impasse_execution_steps
      t.column :tester_id, :integer
      t.column :status, :string, :length => 1, :default=>'0'
      t.column :execution_ts, :datetime
      t.column :notes, :text
    end

#    add_index :impasse_execution_steps, :test_plan_case_id, :name => 'IDX_IMPASSE_EXECUTION_STEPS_01'
    add_index :impasse_execution_steps, :tester_id, :name => 'IDX_IMPASSE_EXECUTION_STEPS_02'
    add_index :impasse_execution_steps, :execution_ts, :name => 'IDX_IMPASSE_EXECUTION_STEPS_03'
  end

  def self.down
    drop_table :impasse_execution_steps
  end
end
