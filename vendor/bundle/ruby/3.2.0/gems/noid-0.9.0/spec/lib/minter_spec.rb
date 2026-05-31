require 'spec_helper'

describe Noid::Minter do
  it 'mints a few random 3-digit numbers' do
    minter = described_class.new(template: '.rddd')
    expect(minter.mint).to match(/\d\d\d/)
  end

  it 'mints random 3-digit numbers, stopping after the 1000th' do
    minter = described_class.new(template: '.rddd')
    1000.times { expect(minter.mint).to match(/^\d\d\d$/) }
    expect { minter.mint }.to raise_exception(RuntimeError, /Exhausted noid sequence pool/)
  end

  it 'mints sequential numbers without limit, adding new digits as needed' do
    minter = described_class.new(template: '.zd')
    expect(minter.mint).to eq('0')
    999.times { expect(minter.mint).to match(/\d/) }
    expect(minter.mint).to eq('1000')
  end

  it 'mints random 4-digit numbers with constant prefix bc' do
    minter = described_class.new(template: 'bc.rdddd')
    1000.times { expect(minter.mint).to match(/^bc\d\d\d\d$/) }
  end

  it 'mints sequential 2-digit numbers with constant prefix 8rf' do
    minter = described_class.new(template: '8rf.sdd')
    expect(minter.mint).to eq('8rf00')
    10.times { expect(minter.mint).to match(/^8rf\d\d$/) }
    expect(minter.mint).to eq('8rf11')
    88.times { expect(minter.mint).to match(/^8rf\d\d$/) }
    expect { minter.mint }.to raise_exception(RuntimeError, /Exhausted noid sequence pool/)
  end

  it 'mints sequential extended-digits' do
    minter = described_class.new(template: '.se')
    expect(29.times.map { minter.mint }.join('')).to eq('0123456789bcdfghjkmnpqrstvwxz')
  end

  it 'mints random 3-extended-digit numbers with constant prefix h9' do
    minter = described_class.new(template: 'h9.reee')

    (minter.template.max).times { expect(minter.mint).to match(/^h9\w\w\w$/) }
    expect { minter.mint }.to raise_exception(RuntimeError, /Exhausted noid sequence pool/)
  end

  it 'mints unlimited sequential numbers with at least 3 extended digits' do
    minter = described_class.new(template: '.zeee')
    (29 * 29 * 29).times { expect(minter.mint).to match(/^\w\w\w/) }
    expect(minter.mint).to match(/^\w\w\w\w/)
  end

  it 'mints random 7-char numbers, with extended digits at chars 2,4,and 5' do
    minter = described_class.new(template: '.rdedeedd')
    1000.times { expect(minter.mint).to match(/^\d\w\d\w\w\d\d$/) }
  end

  it 'mints unlimited mixed digits, adding new extended digits as needed' do
    minter = described_class.new(template: '.zedededed')
    expect(minter.mint).to eq('00000000')
  end

  it 'mints sequential 4-mixed-digit with constant prefix sdd' do
    minter = described_class.new(template: 'sdd.sdede')
    expect(minter.mint).to eq('sdd0000')
    1000.times { expect(minter.mint).to match(/^sdd\d\w\d\w$/) }
    expect(minter.mint).to eq('sdd034h')
  end

  it 'mints random 3 mixed digits plus final (4th) computed check character' do
    minter = described_class.new(template: '.rdedk')
    1000.times { expect(minter.mint).to match(/^\d\w\d\w$/) }
  end

  it 'mints 5 sequential mixed digits plus final extended digit check char' do
    minter = described_class.new(template: '.sdeeedk')
    expect(minter.mint).to eq('000000')
    expect(minter.mint).to eq('000015')
    expect(minter.mint).to eq('00002b')
    1000.times { expect(minter.mint).to match(/^\d\w\w\w\d\w$/) }
    expect(minter.mint).to eq('003f3m')
  end

  it 'mints sequential digits plus check char, with new digits added as needed' do
    minter = described_class.new(template: '.zdeek')
    expect(minter.mint).to eq('0000')
    expect(minter.mint).to eq('0013')
    (10 * 29 * 29 - 2).times { expect(minter.mint).to match(/^\d\w\w\w$/) }
    expect(minter.mint).to eq('10001')
  end

  it 'mints prefix plus random 3 mixed digits plus a check char' do
    minter = described_class.new(template: '63q.redek')
    expect(minter.mint).to match(/63q\w\d\w\w/)
  end

  describe 'validate' do
    it 'validates a prefixed identifier' do
      minter = described_class.new(template: 'foobar.redek')
      id = minter.mint
      expect(minter.valid?(id)).to eq(true)
    end
    it 'validates a prefixless identifier' do
      minter = described_class.new(template: '.redek')
      id = minter.mint
      expect(minter.valid?(id)).to eq(true)
    end
    it 'validates with a new minter' do
      minter = described_class.new(template: '.redek')
      id = minter.mint
      minter2 = described_class.new(template: '.redek')
      expect(minter2.valid?(id)).to eq(true)
    end
    it 'validates an unlimited sequence with mixed digits' do
      minter = described_class.new(template: '.zed')
      1000.times { minter.mint }
      id = minter.mint
      expect(minter.valid?(id)).to eq(true)
    end
  end

  describe 'seed' do
    it 'given a specific seed, identifiers should be replicable' do
      minter = described_class.new(template: '63q.redek')
      minter.seed(1)
      expect(minter.mint).to eq('63q3706')

      minter = described_class.new(template: '63q.redek')
      minter.seed(1)
      expect(minter.mint).to eq('63q3706')
    end

    it 'given a specific seed and sequence, identifiers should be replicable' do
      minter = described_class.new(template: '63q.redek')
      minter.seed(23_456_789, 567)
      mint1 = minter.mint
      dump1 = minter.dump

      minter = described_class.new(template: '63q.redek')
      minter.seed(23_456_789, 567)
      mint2 = minter.mint
      dump2 = minter.dump
      expect(dump1).to eql(dump2)
      expect(mint1).to eql(mint2)
      expect(mint1).to eq('63qb41v') # "63qh305" was the value from a slightly buggy impl
    end
  end

  describe 'dump and reload' do
    it 'dumps the minter state' do
      minter = described_class.new(template: '.sddd')
      d = minter.dump
      expect(d[:template]).to eq('.sddd')
      expect(d[:seq]).to eq(0)

      minter.mint
      minter.mint
      d = minter.dump
      d[:seq] == 2
    end

    it 'dumps the seed, sequence, and counters for the RNG' do
      minter = described_class.new(template: '.rddd')
      d = minter.dump
      expect(d[:seq]).to eq 0
      expect(described_class.new(d).instance_variable_get('@rand').seed).to eq(minter.instance_variable_get('@rand').seed)
    end

    it "allows a random identifier minter to be 'replayed' accurately" do
      minter = described_class.new(template: '.rd')
      d = minter.dump
      arr = 10.times.map { minter.mint }

      minter = described_class.new(d)

      arr2 = 10.times.map { minter.mint }

      expect(arr).to eq(arr2)
    end
  end

  describe 'with large seeds' do
    it 'does not reproduce noids with constructed sequences' do
      minter = described_class.new(template: 'ldpd:.reeeeeeee')
      minter.seed(192_548_637_498_850_379_850_405_658_298_152_906_991)
      first_values = (1..1000).collect { |_c| minter.mint }

      values = []
      (0..999).each do |i|
        minter = described_class.new(template: 'ldpd:.reeeeeeee')
        minter.seed(192_548_637_498_850_379_850_405_658_298_152_906_991, i)
        values << minter.mint
        expect(values[i]).to eql first_values[i]
      end
      values.uniq!
      expect(values.length).to eql 1000
    end
  end

  describe '#remaining' do
    context 'with a sequential template' do
      subject { described_class.new(template: '.sed') }
      context 'with a new minter' do
        it 'returns 290' do
          expect(subject.remaining).to eq 290
        end
      end
      context 'with an in-progress minter' do
        before { 100.times { subject.mint } }
        it 'returns 190' do
          expect(subject.remaining).to eq 190
        end
      end
      context 'with an exhausted minter' do
        before { 290.times { subject.mint } }
        it 'returns 0' do
          expect(subject.remaining).to eq 0
        end
      end
    end
    context 'with a random template' do
      subject { described_class.new(template: '.reek') }
      context 'with a new minter' do
        it 'returns 841' do
          expect(subject.remaining).to eq 841
        end
      end
      context 'with an in-progress minter' do
        before { 441.times { subject.mint } }
        it 'returns 400' do
          expect(subject.remaining).to eq 400
        end
      end
      context 'with an exhausted minter' do
        before { 841.times { subject.mint } }
        it 'returns 0' do
          expect(subject.remaining).to eq 0
        end
      end
    end
    context 'with an unlimited template' do
      subject { described_class.new(template: '.zdd') }
      context 'with a new minter' do
        it 'returns unlimited ' do
          expect(subject.remaining).to eq Float::INFINITY
        end
      end
      context 'with an in-progress minter' do
        before { 51.times { subject.mint } }
        it 'returns unlimited' do
          expect(subject.remaining).to eq Float::INFINITY
        end
      end
      context 'with a minter that appears to be exhausted' do
        before { 101.times { subject.mint } }
        it 'returns unlimited' do
          expect(subject.remaining).to eq Float::INFINITY
        end
      end
    end
  end

  describe 'multithreading-safe example' do
    def stateful_minter
      File.open('minter-state', File::RDWR | File::CREAT, 0644) do |f|
        f.flock(File::LOCK_EX)
        yaml = YAML.load(f.read)
        minter = described_class.new(yaml)
        yield minter
        f.rewind
        yaml = YAML.dump(minter.dump)
        f.write yaml
        f.flush
        f.truncate(f.pos)
      end
    end

    before do
      require 'yaml'
      minter = described_class.new(template: '.reek')
      yaml = YAML.dump(minter.dump)
      File.open('minter-state', 'w') { |f| f.write yaml }
    end

    after do
      File.delete('minter-state')
    end

    it 'hops buckets between runs' do
      bucket_list = []
      10.times do
        stateful_minter do |minter|
          bucket = minter.random_bucket
          bucket_list << bucket
          allow(minter).to receive(:random_bucket) { bucket }
          minter.mint
        end
      end
      expect(bucket_list.uniq.count).to be > 1
    end

    it 'persists state to the filesystem' do
      # TODO: This is not testing any expectations. Clarify intent and fix.
      skip
      File.open('minter-state', File::RDWR | File::CREAT, 0644) do|f|
        f.flock(File::LOCK_EX)
        yaml = YAML.load(f.read)

        minter = described_class.new(yaml)

        f.rewind
        yaml = YAML.dump(minter.dump)
        f.write yaml
        f.flush
        f.truncate(f.pos)
      end
    end
  end
end
