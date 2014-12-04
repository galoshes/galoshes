
require_relative 'provider_base'

class Chef::Provider::GaloshesLaunchConfiguration < Chef::Provider::GaloshesBase
  def clarify_attributes
    @current_resource.placement_tenancy ||= 'default'
  end

  def load_current_resource
    require 'fog'
    require 'fog/aws/models/auto_scaling/configurations'

    aws_access_key_id = new_resource.aws_access_key_id || node['galoshes']['aws_access_key_id']
    aws_secret_access_key = new_resource.aws_secret_access_key || node['galoshes']['aws_secret_access_key']
    region = new_resource.region || node['galoshes']['region']

    @fog_as = Fog::AWS::AutoScaling.new(:aws_access_key_id => aws_access_key_id, :aws_secret_access_key => aws_secret_access_key, :region => region)
    @collection = Fog::AWS::AutoScaling::Configurations.new(:service => @fog_as)
    @current_resource = @collection.new(:id => new_resource.name, :service => @fog_as)

    @current_resource.reload
    clarify_attributes
    @exists = !(@current_resource.created_at.nil?)
    Chef::Log.debug("#{resource_str} current_resource: #{@current_resource} exists: #{@exists}")
    Chef::Log.debug(@current_resource.inspect)

    @current_resource
  end

  def action_create
    converge_if(!(@exists), "create #{resource_str}") do
      create_attributes = [:id, :image_id, :instance_type, :security_groups, :block_device_mappings, :key_name, :user_data, :kernel_id, :ramdisk_id, :placement_tenancy]
      create_attributes.each do |attr|
        value = new_resource.send(attr)
        Chef::Log.debug("attr: #{attr} value: #{value} nil? #{value.nil?}")
        @current_resource.send("#{attr}=", value) unless value.nil?
      end
      Chef::Log.debug("current_resource before save: #{current_resource}")

      result = @current_resource.save
      @exists = !(result.nil?)
      clarify_attributes
    end
  end

  def action_delete
    converge_if(@exists, "delete #{resource_str}") do
      @current_resource.destroy
      @exists = false
      new_resource.updated_by_last_action(true)
    end
  end

  def action_update
    update_attributes = [:id, :image_id, :instance_type, :block_device_mappings, :key_name, :kernel_id, :ramdisk_id, :placement_tenancy]
    update_attributes.each do |attr|
      verify_attribute(attr) {}
    end

    Chef::Log.info("verify #{resource_str}.security_groups")
    current_value = @current_resource.security_groups.sort unless @current_resource.security_groups.nil?
    new_value = new_resource.security_groups.sort unless @new_resource.security_groups.nil?
    Chef::Log.info("#{resource_str}.security_groups cur: #{current_value.inspect} new: #{new_value.inspect}")
    converge_if(current_value != new_value, "update '#{resource_str}.security_groups from '#{current_value}' to '#{new_value}'") {}

    # FIX ME - :user_data needs to be added, but is broken in fog
  end
end
