class Post < ActiveRecord::Base
  has_many :comments

  trigger.after(:insert, :update).of(:content) { "SELECT 1;" }
end
