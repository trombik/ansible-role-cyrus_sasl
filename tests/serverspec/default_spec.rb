require "spec_helper"
require "serverspec"

package = "cyrus-sasl"
sasldblistusers_command = "sasldblistusers2"
sasldb_file = "/etc/sasldb2.db"
default_user = "root"
default_group = "root"

case os[:family]
when "freebsd"
  sasldb_file = "/usr/local/etc/sasldb2.db"
  default_group = "wheel"
end

describe package(package) do
  it { should be_installed }
end 

describe file(sasldb_file) do
  it { should be_file }
  it { should be_mode 600 }
  it { should be_owned_by default_user }
  it { should be_grouped_into default_group }
end

describe command(sasldblistusers_command) do
  its(:stdout) { should match(/^foo@reallyenglish\.com: userPassword$/) }
  its(:stderr) { should match(/^$/) }
  its(:exit_status) { should eq 0 }
end
