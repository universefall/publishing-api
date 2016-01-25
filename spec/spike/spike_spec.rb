require "rails_helper"

RSpec.describe "Spike" do
  let(:first_content_id) { SecureRandom.uuid }
  let(:second_content_id) { SecureRandom.uuid }
  let(:third_content_id) { SecureRandom.uuid }

  before do
    FactoryGirl.create(:link_set, content_id: first_content_id, links: [
      FactoryGirl.create(:link, target_content_id: second_content_id, link_type: "foo"),
      FactoryGirl.create(:link, target_content_id: third_content_id, link_type: "bar"),
    ])

    FactoryGirl.create(:link_set, content_id: second_content_id, links: [
      FactoryGirl.create(:link, target_content_id: third_content_id, link_type: "baz"),
    ])
  end

  def execute_recursive_query(content_id, link_type = nil)
    results = ActiveRecord::Base.connection.execute <<-SQL
      with recursive reverse_dependencies as (
        select '#{content_id}'::varchar as content_id

        union

        select s.content_id from links l
        join link_sets s on l.link_set_id = s.id
        join reverse_dependencies r on l.target_content_id = r.content_id
        #{ "where l.link_type = '#{link_type}'" if link_type }

      ) select * from reverse_dependencies r;
    SQL

    results.to_a
  end

  it "returns the expected results" do
    expect(execute_recursive_query(first_content_id)).to match_array [
      { "content_id" => first_content_id },
    ]

    expect(execute_recursive_query(second_content_id)).to match_array [
      { "content_id" => first_content_id },
      { "content_id" => second_content_id },
    ]

    expect(execute_recursive_query(third_content_id)).to match_array [
      { "content_id" => first_content_id },
      { "content_id" => second_content_id },
      { "content_id" => third_content_id },
    ]

    expect(execute_recursive_query(second_content_id, "missing")).to match_array [
      { "content_id" => second_content_id },
    ]

    expect(execute_recursive_query(second_content_id, "foo")).to match_array [
      { "content_id" => first_content_id },
      { "content_id" => second_content_id },
    ]
  end
end
