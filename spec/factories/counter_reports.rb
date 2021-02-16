# frozen_string_literal: true

FactoryBot.define do
  factory :counter_report do
    session do
      ip = 1.upto(4).map { |_| Random.rand(255) }.join(".")
      from = 1_483_228_800.0 # 2017-01-01
      to = Time.now
      date = Time.at(from + rand * (to.to_f - from.to_f)).strftime("%Y-%m-%d")
      "#{ip}|Some UserAgent String/1.0|#{date}|#{Random.rand(24)}"
    end
    institution do
      inst = %w[1 45 987 43 24 643 22 6 18 745]
      inst[Random.rand(10)]
    end
    noid { Noid::Rails::Service.new.mint }
    model { "FileSet" }
    section { "" }
    section_type { "" }
    investigation { 1 }
    request { 0 }
    access_type do
      at = ["Controlled", "OA_Gold"]
      at[Random.rand(2)]
    end
    press { 1 }
    parent_noid { Noid::Rails::Service.new.mint }
  end
end
