#
# Cookbook Name:: mapr_hue
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

if node['fqdn'] == node["mapr"]["hue"] 
  print "\nWill install Hue and Httpfs on node: #{node['fqdn']}\n"

  # Initialize some variables for later
  first_rm="#{node[:mapr][:rm][0]}"
  hadoop_version=`ls /opt/mapr/hadoop|grep hadoop-2|tr -d '\n'`
  yarn_cluster_name=`cat /opt/mapr/hadoop/#{hadoop_version}/etc/hadoop/yarn-site.xml|grep "#{node[:mapr][:clustername]}"|awk 'BEGIN {FS=">"} {print $2}'|awk ' BEGIN {FS="<"} {print $1}'|tr -d '\n'`
  hive_install_version=`yum list --showduplicates mapr-hive|grep "#{node[:mapr][:hive_version]}"|awk '{print $2}'|tail -1 - |tr -d '\n'`

# Install httpfs and hue, and hive if not done before
  package 'mapr-httpfs'
  package 'mapr-hue'

  if "#{hive_install_version}" != `yum list installed|grep mapr-hive.noarch|awk '{print $2}'|tr -d '\n'`
    include_recipe "mapr_hive::mapr_hive"
    include_recipe "mapr_hive::mapr_hive-site_config"
  end 

  ## SETUP HUE.INI FILE
  ruby_block "Alter_hue.ini" do
    block do

      node.default[:hue][:version] = `ls /opt/mapr/hue|grep hue-|tr -d '\n'`

      file  = Chef::Util::FileEdit.new("/opt/mapr/hue/#{node[:hue][:version]}/desktop/conf/hue.ini")

      ##  CORE DESKTOP FEATURES
      # Update Blacklist to include impala
      file.search_file_replace_line("app_blacklist=spark,search,zookeeper","app_blacklist=spark,search,zookeeper,impala")
     
      # Correct Time Zone
      file.search_file_replace_line("teme_zone=America/Los_Angeles","      time_zone=America/New_York")


      ## HTTPFS/WEBHDFS ENTRIES 
      # Replace 'localhost' with FQDN of httpfs server
      file.search_file_replace_line("webhdfs_url=http://localhost:14000/webhdfs/v1","      webhdfs_url=http://#{node[:mapr][:hue]}:14000/webhdfs/v1")

      ##  HOUSEKEEPING...     
      # Comment out all 'submit_to' references
      file.search_file_replace("submit_to","      #submit_to")


      ##  YARN STUFF
      # Insert Resourcemanager FQDN
      file.search_file_replace_line("resourcemanager_host=localhost","      resourcemanager_host=#{first_rm}")

      # uncomment resourcemanager port
      file.search_file_replace_line("## resourcemanager_port=8032","      resourcemanager_port=8032")

      # Insert correct 'submit_to' for Yarn 
      file.search_file_replace_line("# Change this if your YARN cluster is secured","      submit_to=True

      # Change this if your YARN cluster is secured")


#      # Uncomment resourcemanager url
#      file.search_file_replace_line("## resourcemanager_api_url=http:","      resourcemanager_api_url=http:#{first_rm}")


      # Uncomment out historyserver web stuff
      file.search_file_replace_line("## history_server_api_url=http://localhost","     history_server_api_url=http://#{node[:mapr][:hs]}:19888")


      #  Yarn HA section
      file.search_file_replace_line("# Configuration for MapReduce","      [[[ha]]]


      # Resource Manager logical name (required for HA)
      logical_name=#{yarn_cluster_name}

  # Configuration for MapReduce (MR1)")

      # DONE Yarn HA section...


      ## MR1 SECTION
      
      # Insert correct 'submit_to for MR1
      file.search_file_replace_line("# Change this if your MapReduce cluster is secured","      submit_to=False

      # Change this if your MapReduce cluster is secured")

      
      ##  OOZIE SECTION

      #  Put oozie server url in place
      file.search_file_replace_line("oozie_url=http://localhost:11000/oozie","      oozie_url=http://#{node[:mapr][:oozie]}:11000/oozie")


      ## HIVE SECTION

      # Insert Hiveserver2 host information
      file.search_file_replace_line("hive_server_host=localhost","  hive_server_host=#{node[:mapr][:hs2]}")

      # Uncomment Hiveserver2 port
      file.search_file_replace_line("## hive_server_port=10000","hive_server_port=10000")

      file.write_file

      end
    end
#
# 
end

