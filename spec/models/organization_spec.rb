require 'spec_helper'

describe Organization do
  it "returns a list of projects" do
    expect(Organization.repositories).to be_an_instance_of(Array)
  end

  it "returns a list of project names" do
    expect(Organization.repository_names).to be_an_instance_of(Array)
  end

  it "returns an array of milestones" do
    expect(Organization.milestones).to be_an_instance_of(Array)
  end
end
