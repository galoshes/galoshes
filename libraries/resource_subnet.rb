require 'chef/resource/lwrp_base'

class Chef::Resource::GaloshesSubnet < Chef::Resource::LWRPBase
  self.resource_name = :galoshes_subnet
  actions :create
  default_action :create

  attribute :cidr_block, :kind_of => [String]
  attribute :subnet_id, :kind_of => [String], :default => nil
  attribute :availability_zone, :kind_of => [String]
  attribute :vpc_id, :kind_of => [String]
  attribute :tag_set, :kind_of => [Hash], :default => {}
  attribute :aws_access_key_id, :default => nil
  attribute :aws_secret_access_key, :default => nil
  attribute :region, :default => 'us-east-1'
end
