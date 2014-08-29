class Survey < ActiveRecord::Base
  attr_accessor :creator

  has_many :responses, class_name: 'ResponseSurvey'
  has_many :users, through: :responses
  belongs_to :user
  
  before_create :set_user
  
  private
    def set_user
      self.user = self.creator if self.creator
    end

end