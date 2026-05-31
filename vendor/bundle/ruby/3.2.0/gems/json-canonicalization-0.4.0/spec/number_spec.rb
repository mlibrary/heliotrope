require_relative 'spec_helper'

describe "conversions" do
  {
    -1/0.0                    => RangeError,
    -9007199254740992         => '-9007199254740992',
    0                         => '0',
    0.000001                  => '0.000001',
    0/0.0                     => RangeError,
    1/0.0                     => RangeError,
    1e+21                     => '1e+21',
    9.999999999999997e+22     => '9.999999999999997e+22',
    9.999999999999997e-7      => '9.999999999999997e-7',
    9007199254740992          => '9007199254740992',
    9007199254740994          => '9007199254740994',
    9007199254740996          => '9007199254740996',
    999999999999999700000     => '999999999999999700000',
    999999999999999900000     => '999999999999999900000',
    333333333.33333329        => '333333333.3333333',
    # -5e-324                 => '-5e-324', # Outside Ruby Range
    # 1.0000000000000001e+23  => '1.0000000000000001e+23', # Outside Ruby Range
    # 295147905179352830000   => '295147905179352830000', # Outside Ruby Range
    #-1.7976931348623157e+308 => '-1.7976931348623157e+308',  # Outside Ruby Range
    #1.7976931348623157e+308  => '1.7976931348623157e+308',  # Outside Ruby Range
    #1e+23                    => '1e+23', # Outside Ruby
    #5e-324                   => '5e-324',  # Outside Ruby Range
  }.each do |data, expected|
    if expected.is_a?(String)
      it "converts #{data} to #{expected}" do
        expect(data.to_json_c14n).to eq expected
      end
    else
      it "raises #{expected} for #{data}" do
        expect {data.to_json_c14n}.to raise_error(expected)
      end
    end
  end
end
