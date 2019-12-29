# `trombik.cyrus_sasl`

Installs `cyrus-sasl`, `saslauthd` and configures users in SASL DB file. This
role supports local SASL database and `saslauthd` only. If you want other back-ends, this is
not for you.

## `sasl_check_pw`

This role installs a python script to check password of a user under
`/usr/local/bin` on all platforms. As there is no way to see if the password
defined in a role variable and the one in the database are same, the script
reads `cyrus_sasl_sasldb_file` and looks for the user and its password. The
script assumes that `cyrus_sasl_sasldb_file` is `dbm` format.

```sh
sasl_check_pw path user domain
```

`path` is the path to `cyrus_sasl_sasldb_file`. `user` is the user name in
`cyrus_sasl_sasldb_file`, and `domain` is the domain name where the user belong
to. Set the password to check in an environment variable, `userPassword`. When
the password matches the one in `cyrus_sasl_sasldb_file`, it prints `matched`
to `stdout`. When it does not, it prints `does not match` to `stdout`. It must
be executed by a user with read permission on `cyrus_sasl_sasldb_file`.

# Requirements

None

# Role Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `cyrus_sasl_package` | the package name of `cyrus-sasl` | `{{ __cyrus_sasl_package }}` |
| `cyrus_sasl_saslauthd_service` | the service name of `saslauthd` | `{{ __cyrus_sasl_saslauthd_service }}` |
| `cyrus_sasl_saslauthd_enable` | enable `saslauthd` if yes | yes |
| `cyrus_sasl_saslauthd_flags` | dict of service variables and their values (see below) | `{}` |
| `cyrus_sasl_saslauthd_flags_default` | default value of service variables and their values | `{{ __cyrus_sasl_saslauthd_flags_default }}` |
| `cyrus_sasl_plugin_dir` | the plugin directory where application config resides | `{{ __cyrus_sasl_plugin_dir }}` |
| `cyrus_sasl_saslpassword_command` | the command to manage password of users | `{{ __cyrus_sasl_saslpassword_command }}` |
| `cyrus_sasl_sasldblistusers_command` | the command to list users in the database | `{{ __cyrus_sasl_sasldblistusers_command }}` |
| `cyrus_sasl_sasldb_file` | path to SASL DB file | `{{ __cyrus_sasl_sasldb_file }}` |
| `cyrus_sasl_sasldb_owner` | owner of SASL DB file | `root` |
| `cyrus_sasl_sasldb_group` | group of SASL DB file | `{{ __cyrus_sasl_sasldb_group }}` |
| `cyrus_sasl_sasldb_file_permission` | file permission of SASL DB file | `{{  __cyrus_sasl_sasldb_file_permission }}` |
| `cyrus_sasl_config` | a dict of application config (see below) | `{}` |
| `cyrus_sasl_user` | a dict of users in SASL DB file (see below) | `{}` |

## `cyrus_sasl_saslauthd_flags`

This variable is a dict of variables of startup configuration files, such as
files under `/etc/default`, `/etc/sysconfig`, and `/etc/rc.conf.d`. It is
assumed that the files are `source`d by startup mechanism with `sh(1)`. A key
in the dict is name of the variable in the file, and the value of the key is
value of the variable. The variable is combined with a variable whose name is
same as this variable, but postfixed with `_default` (explained below) and the
result creates the startup configuration file, usually a file consisting of
lines of `key="value"` under appropriate directory for the platform.

When the platform is OpenBSD, the above explanation does not apply. In this
case, the only valid key is `flags` and the value of it is passed to
`daemon_flags` described in [`rc.conf(5)`](http://man.openbsd.org/rc.conf),
where `daemon` is the name of one of the `rc.d(8)` daemon control scripts.

## `cyrus_sasl_saslauthd_flags_default`

This variable is a dict of keys and values derived from upstream's default
configuration, and is supposed to be a constant unless absolutely necessary. By
default, the role creates a startup configuration file for each platform with
this variable, identical to default one.

When the platform is OpenBSD, the variable has a single key, `flags` and its
value is empty string.

## `cyrus_sasl_config`

The key is application name. The value is a dict in which the key is a variable
name and the value is its value. Example:

```yaml
cyrus_sasl_config:
    myapp:
        pwcheck_method: saslauthd
```

## `cyrus_sasl_user`

The key is user name and its values is a dict.

| Key | Value |
|-----|-------|
| `domain` | the domain of the user |
| `password` | the password of the user |
| `appname` | the `appname` of the user |
| `state` | either `present` or `absent`. The role creates the user if `present`, or deletes if `absent` |

```
cyrus_sasl_user:
  foo:
    domain: reallyenglish.com
    password: password
    appname: argus
    state: present
```

## Debian

| Variable | Default |
|----------|---------|
| `__cyrus_sasl_package` | `libsasl2-2` |
| `__cyrus_sasl_saslauthd_service` | `saslauthd` |
| `__cyrus_sasl_saslauthd_flags_default` | `{"MECHANISMS"=>"pam", "MECH_OPTIONS"=>"", "THREADS"=>5, "OPTIONS"=>"-c -m /var/run/saslauthd"}` |
| `__cyrus_sasl_plugin_dir` | `/usr/lib/sasl2` |
| `__cyrus_sasl_saslpassword_command` | `saslpasswd2` |
| `__cyrus_sasl_sasldblistusers_command` | `sasldblistusers2` |
| `__cyrus_sasl_sasldb_file` | `/etc/sasldb2` |
| `__cyrus_sasl_sasldb_file_permission` | `0660` |
| `__cyrus_sasl_sasldb_group` | `root` |

## FreeBSD

| Variable | Default |
|----------|---------|
| `__cyrus_sasl_package` | `cyrus-sasl` |
| `__cyrus_sasl_saslauthd_service` | `saslauthd` |
| `__cyrus_sasl_saslauthd_flags_default` | `{}` |
| `__cyrus_sasl_plugin_dir` | `/usr/local/lib/sasl2` |
| `__cyrus_sasl_saslpassword_command` | `saslpasswd2` |
| `__cyrus_sasl_sasldblistusers_command` | `sasldblistusers2` |
| `__cyrus_sasl_sasldb_file` | `/usr/local/etc/sasldb2` |
| `__cyrus_sasl_sasldb_file_permission` | `600` |
| `__cyrus_sasl_sasldb_group` | `wheel` |

## OpenBSD

| Variable | Default |
|----------|---------|
| `__cyrus_sasl_package` | `cyrus-sasl--` |
| `__cyrus_sasl_saslauthd_service` | `saslauthd` |
| `__cyrus_sasl_saslauthd_flags_default` | `{"flags"=>"-a getpwent"}` |
| `__cyrus_sasl_plugin_dir` | `/usr/local/lib/sasl2` |
| `__cyrus_sasl_saslpassword_command` | `saslpasswd2` |
| `__cyrus_sasl_sasldblistusers_command` | `sasldblistusers2` |
| `__cyrus_sasl_sasldb_file` | `/etc/sasldb2` |
| `__cyrus_sasl_sasldb_file_permission` | `600` |
| `__cyrus_sasl_sasldb_group` | `wheel` |

## RedHat

| Variable | Default |
|----------|---------|
| `__cyrus_sasl_package` | `cyrus-sasl` |
| `__cyrus_sasl_saslauthd_service` | `saslauthd` |
| `__cyrus_sasl_saslauthd_flags_default` | `{"SOCKETDIR"=>"/run/saslauthd", "MECH"=>"pam", "FLAGS"=>""}` |
| `__cyrus_sasl_plugin_dir` | `/usr/lib64/sasl2` |
| `__cyrus_sasl_saslpassword_command` | `saslpasswd2` |
| `__cyrus_sasl_sasldblistusers_command` | `sasldblistusers2` |
| `__cyrus_sasl_sasldb_file` | `/etc/sasldb2` |
| `__cyrus_sasl_sasldb_file_permission` | `0640` |
| `__cyrus_sasl_sasldb_group` | `root` |

# Dependencies

None

# Example Playbook

```yaml
- hosts: localhost
  roles:
    - ansible-role-cyrus-sasl
  vars:
    cyrus_sasl_user:
      foo:
        domain: reallyenglish.com
        password: password
        appname: argus
        state: present
    cyrus_sasl_config:
      myapp:
        pwcheck_method: saslauthd
      argus:
        pwcheck_method: auxprop
        auxprop_plugin: sasldb
        mech_list: DIGEST-MD5
    cyrus_sasl_sasldb_group: "{% if ansible_os_family == 'Debian' %}nogroup{% else %}nobody{% endif %}"
    cyrus_sasl_sasldb_file_permission: "0640"

    extra_variables_debian:
      THREADS: 6
    extra_variables_redhat:
      FLAGS: -n 6
    extra_variables_freebsd:
      saslauthd_flags: -a pam -n 6
    extra_variables_openbsd:
      flags: -a getpwent -n 6
    cyrus_sasl_saslauthd_flags: "{% if ansible_os_family == 'Debian' %}{{ extra_variables_debian }}{% elif ansible_os_family == 'RedHat' %}{{ extra_variables_redhat }}{% elif ansible_os_family == 'FreeBSD' %}{{ extra_variables_freebsd }}{% elif ansible_os_family == 'OpenBSD' %}{{ extra_variables_openbsd }}{% endif %}"
```

# License

```
Copyright (c) 2017 Tomoyuki Sakurai <y@trombik.org>

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
```

# Author Information

Tomoyuki Sakurai <y@trombik.org>

This README was created by [qansible](https://github.com/trombik/qansible)
