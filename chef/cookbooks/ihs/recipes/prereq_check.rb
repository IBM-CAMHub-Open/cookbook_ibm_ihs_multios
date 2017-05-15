# Cookbook Name:: ihs
# Recipe:: prereq_check
#
# Copyright IBM Corp. 2016, 2017
#

# <> Prerequisites recipe (prereq_check.rb)
# <> Verify required prerequisites, validate input

# Fail if ports < 1024 are supplied with install_mode != admin
if node['ihs']['port'].to_i < 1024 && node['ihs']['install_mode'] != 'admin'
  raise 'Port numbers under 1024 are not allowed in non-admin mode.'
end

if node['ihs']['admin_server']['port'].to_i < 1024 && node['ihs']['install_mode'] != 'admin' && node['ihs']['admin_server']['enabled'].to_s == 'true'
  raise 'Port numbers under 1024 are not allowed in non-admin mode.'
end

if node['ihs']['ssl']['port'].to_i < 1024 && node['ihs']['install_mode'] != 'admin' && node['ihs']['ssl']['enabled'].to_s == 'true'
  raise 'Port numbers under 1024 are not allowed in non-admin mode.'
end

# Validate requested IHS version
raise "Requested version #{node['ihs']['version']} format is invalid, expected <Release>.<Version>.<ML>.<FP>" if node['ihs']['version'].split('.').length != 4

if ihs_installed?
  # Get version of installed product
  inst_vers = ihs_installed_version
  log "IHS version #{inst_vers} is present"

  # Validate fixpack installation requests
  raise "Downgrade is not supported \(#{node['ihs']['version']} is lower than the installed version #{inst_vers}\)" if (node['ihs']['version'].split('.') <=> inst_vers.split('.')) < 0

  # Only allow fixpack installations
  raise "Upgrade is only supported at fixpack level, #{node['ihs']['version']} cannot be installed over #{inst_vers}" unless (node['ihs']['version'].split('.').slice(0, 3) <=> inst_vers.split('.').slice(0, 3)) == 0

  # Let them know we're upgrading
  log "Upgrading IHS from #{inst_vers} to #{node['ihs']['version']}" unless (node['ihs']['version'] <=> inst_vers) == 0
end

# Fail if install_dir exists but product is not installed
unless ihs_installed?
  if File.exist?(node['ihs']['install_dir'])
    raise 'Provided installation directory already exists on the macihne, please choose another'
  end
end

# Validate bitness entry; v90 and up only
if node['ihs']['version'].split('.').first.to_i < 9
  raise "Select either '32' or '64' for bitness parameter" unless ['32', '64'].include? node['ihs']['features']['bitness']
end

# System must have valid fqdn, or install will silently fail
raise 'Please ensure hostname -f returns a valid FQDN' if node['fqdn'].nil?

# TODO: Validate plugin install dir; must not be a parent or sub-directory of node['ihs']['install_dir']
# TODO: Validate platform

# Check Free Space on install_dir
ibm_cloud_utils_freespace 'check-freespace-install-dir-directory' do
  path node['ihs']['install_dir']
  required_space 500
  continue true
  action :check
  error_message "Please make sure you have at least 500MB free space under #{node['ihs']['install_dir']}"
  not_if { ihs_installed? }
end

# Check Free Space on temp_dir
ibm_cloud_utils_freespace 'check-freespace-temp-dir-directory' do
  path node['ibm']['temp_dir']
  required_space 500
  continue true
  action :check
  error_message "Please make sure you have at least 500MB free space under #{node['ibm']['temp_dir']}"
  not_if { ihs_installed? }
end