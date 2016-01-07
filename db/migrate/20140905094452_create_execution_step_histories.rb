class CreateExecutionStepHistories < ActiveRecord::Migration
  def self.up
    create_table :impasse_execution_step_histories do |t|
      t.belongs_to :impasse_execution
      t.belongs_to :test_step
      t.column :status, :string, :length => 1, :default=>'0'
      t.column :execution_ts, :datetime
      t.column :executor_id, :integer, :null => false
      t.column :notes, :text
    end

  end

  def self.down
    drop_table :impasse_execution_step_histories
  end
end
