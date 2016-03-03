require 'spec_helper'
describe 'swapfile' do

  context 'with defaults for all parameters' do
    it { should contain_class('swapfile') }
  end
end
