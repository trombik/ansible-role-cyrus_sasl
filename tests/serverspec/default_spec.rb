require "spec_helper"
require "serverspec"

packages = []
sasldblistusers_command = "sasldblistusers2"
sasldb_file = "/etc/sasldb2"
sasllib_dir = "/usr/lib/sasl2"
group = "nobody"
default_user = "root"
default_group = "root"
service = "saslauthd"

sasldb_permission = 640

case os[:family]
when "openbsd"
  packages = ["cyrus-sasl"]
  default_group = "wheel"
  sasldb_file = "/etc/sasldb2.db"
  sasllib_dir = "/usr/local/lib/sasl2"
when "ubuntu"
  group = "nogroup"
  packages = ["libsasl2-2", "sasl2-bin"]
when "redhat"
  packages = ["cyrus-sasl"]
  sasllib_dir = "/usr/lib64/sasl2"
when "freebsd"
  packages = ["cyrus-sasl"]
  sasldb_file = "/usr/local/etc/sasldb2.db"
  sasllib_dir = "/usr/local/lib/sasl2"
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

describe command("env userPassword='password' /usr/local/bin/sasl_check_pw #{sasldb_file} foo reallyenglish.com") do
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
    its(:content) { should match(/^THREADS="6"$/) }
    its(:content) { should match(/^OPTIONS="-c -m #{Regexp.escape("/var/run/saslauthd")}"$/) }
  end

  describe process("saslauthd") do
    its(:count) { should eq 6 }
    its(:args) { should match(/-a pam -c -m #{Regexp.escape("/var/run/saslauthd")} -n 6/) }
  end
when "freebsd"
  describe package("security/cyrus-sasl2-saslauthd") do
    it { should be_installed }
  end

  describe file("/etc/rc.conf.d/saslauthd") do
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    its(:content) { should match(/^saslauthd_flags="-a pam -n 6"$/) }
  end

  describe process("saslauthd") do
    its(:args) do
      pending "process resource does not work on FreeBSD (ps -C is linuxism)"
      should match(/-a pam -n 6/)
    end
  end

  describe command("ps -ax -o command") do
    its(:exit_status) { should eq 0 }
    its(:stderr) { should eq "" }
    its(:stdout) { should match(/saslauthd\s.*-a pam -n 6/) }
  end
when "openbsd"
  describe file("/etc/rc.conf.local") do
    its(:content) { should match(/^saslauthd_flags=-a getpwent -n 6/) }
  end
  describe command("ps -ax -o command") do
    its(:exit_status) { should eq 0 }
    its(:stderr) { should eq "" }
    its(:stdout) { should match(/saslauthd\s.*-a getpwent -n 6/) }
  end
when "redhat"
  describe file("/etc/sysconfig/saslauthd") do
    it { should exist }
    it { should be_mode 644 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    its(:content) { should match(/^SOCKETDIR="#{Regexp.escape("/run/saslauthd")}"$/) }
    its(:content) { should match(/^MECH="pam"$/) }
    its(:content) { should match(/^FLAGS="-n 6"$/) }
  end
  describe process("saslauthd") do
    its(:count) { should eq 6 }
    its(:args) { should match(/-m #{Regexp.escape("/run/saslauthd")} -a pam -n 6/) }
  end
end

describe file "#{sasllib_dir}/myapp.conf" do
  it { should be_file }
  it { should be_mode 644 }
  it { should be_owned_by default_user }
  it { should be_grouped_into default_group }
  its(:content) { should match(/^pwcheck_method: saslauthd$/) }
end

describe file "#{sasllib_dir}/argus.conf" do
  it { should be_file }
  it { should be_mode 644 }
  it { should be_owned_by default_user }
  it { should be_grouped_into default_group }
  its(:content) { should match(/^pwcheck_method: auxprop$/) }
  its(:content) { should match(/^auxprop_plugin: sasldb$/) }
  its(:content) { should match(/^mech_list: DIGEST-MD5$/) }
end

describe command("testsaslauthd -u vagrant -p vagrant -s login") do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/^0: OK "Success."$/) }
  its(:stderr) { should eq "" }
end

describe service(service) do
  it { should be_enabled }
  it { should be_running }
end
