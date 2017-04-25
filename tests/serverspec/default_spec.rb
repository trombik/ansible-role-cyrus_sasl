require "spec_helper"
require "serverspec"

packages = []
sasldblistusers_command = "sasldblistusers2"
sasldb_file = "/etc/sasldb2"
group = "sasl"
default_user = "root"
default_group = "root"

sasldb_permission = 660

case os[:family]
when "openbsd"
  packages = [ "cyrus-sasl" ]
  group = "wheel"
  default_group = "wheel"
  sasldb_permission = 600
  sasldb_file = "/etc/sasldb2.db"
when "ubuntu"
  packages = [ "libsasl2-2", "sasl2-bin" ]
when "redhat"
  packages = [ "cyrus-sasl-lib" ]
  sasldb_permission = 640
  group = "root"
when "freebsd"
  packages = [ "cyrus-sasl" ]
  sasldb_file = "/usr/local/etc/sasldb2.db"
  sasldb_permission = 600
  group = "wheel"
  default_group = "wheel"
end

packages.each do |p|
  describe package(p) do
    it { should be_installed }
  end 
end

describe file(sasldb_file) do
  it { should be_file }
  it { should be_mode sasldb_permission }
  it { should be_owned_by default_user }
  it { should be_grouped_into group }
end

describe file("/usr/local/bin/sasl_check_pw") do
  it { should be_file }
  it { should be_mode 755 }
  it { should be_owned_by default_user }
  it { should be_grouped_into default_group }
end

describe command("env userPassword='password' /usr/local/bin/sasl_check_pw #{ sasldb_file } foo reallyenglish.com") do
  its(:stdout) { should match(/^matched$/) }
  its(:stderr) { should match(/^$/) }
  its(:exit_status) { should eq 0 }
end

describe command(sasldblistusers_command) do
  its(:stdout) { should match(/^foo@reallyenglish\.com: userPassword$/) }
  its(:stderr) { should match(/^$/) }
  its(:exit_status) { should eq 0 }
end
