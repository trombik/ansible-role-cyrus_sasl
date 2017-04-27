require "spec_helper"
require "serverspec"

packages = []
sasldblistusers_command = "sasldblistusers2"
sasldb_file = "/etc/sasldb2"
sasllib_dir = "/usr/lib/sasl2"
group = "sasl"
default_user = "root"
default_group = "root"
service = "saslauthd"

sasldb_permission = 660

case os[:family]
when "openbsd"
  packages = [ "cyrus-sasl" ]
  group = "wheel"
  default_group = "wheel"
  sasldb_permission = 600
  sasldb_file = "/etc/sasldb2.db"
  sasllib_dir = "/usr/local/lib/sasl2"
when "ubuntu"
  packages = [ "libsasl2-2", "sasl2-bin" ]
when "redhat"
  packages = [ "cyrus-sasl" ]
  sasldb_permission = 640
  group = "root"
  sasllib_dir = "/usr/lib64/sasl2"
when "freebsd"
  packages = [ "cyrus-sasl" ]
  sasldb_file = "/usr/local/etc/sasldb2.db"
  sasldb_permission = 600
  sasllib_dir = "/usr/local/lib/sasl2"
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

case os[:family]
when "ubuntu"
  describe file("/etc/default/saslauthd") do
    its(:content) { should match(/^START=yes$/) }
    its(:content) { should match(/^MECHANISMS="pam"$/) }
    its(:content) { should match(/^MECH_OPTIONS=""$/) }
    its(:content) { should match(/^THREADS=5$/) }
    its(:content) { should match(/^OPTIONS="-c -m \/var\/run\/saslauthd"$/) }
  end
when "freebsd"
  describe package("security/cyrus-sasl2-saslauthd") do
    it { should be_installed }
  end
end

describe file ("#{ sasllib_dir }/myapp.conf") do
  it { should be_file }
  it { should be_mode 644 }
  it { should be_owned_by default_user }
  it { should be_grouped_into default_group }
  its(:content) { should match(/^pwcheck_method: saslauthd$/) }
end

describe file ("#{ sasllib_dir }/argus.conf") do
  it { should be_file }
  it { should be_mode 644 }
  it { should be_owned_by default_user }
  it { should be_grouped_into default_group }
  its(:content) { should match(/^pwcheck_method: auxprop$/) }
  its(:content) { should match(/^auxprop_plugin: sasldb$/) }
  its(:content) { should match(/^mech_list: DIGEST-MD5$/) }
end

describe command("testsaslauthd -u vagrant -p vagrant -s login") do
  its(:exit_status) { should_not eq 0 }
  its(:stdout) { should_not match(/^0: OK "Success."$/) }
end

describe service(service) do
  it { should_not be_enabled }
  it do
    pending "serverspec does not use onestatus to check the status" if os[:family] == "freebsd"
    should_not be_running
  end
end
