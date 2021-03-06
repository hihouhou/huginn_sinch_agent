require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::SinchAgent do
  before(:each) do
    @valid_options = Agents::SinchAgent.new.default_options
    @checker = Agents::SinchAgent.new(:name => "SinchAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
