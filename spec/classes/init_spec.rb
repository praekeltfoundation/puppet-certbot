require 'spec_helper'

describe 'certbot' do
  on_supported_os.each do |os, facts|
    let(:facts) { facts }
    let(:params) { {:email => 'letsencrypt@example.com'} }

    context "on #{os}" do
      it { is_expected.to compile }
    end
  end
end
