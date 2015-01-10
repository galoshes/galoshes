# TODO
# validate in resource def that availability zone or subnet, but not both set
# compare lists with set to make sure order doesn't matter

require 'ostruct'

class Chef::Provider::GaloshesLoadBalancer < Chef::Provider::GaloshesBase
  include Galoshes::DeleteMixin

  def load_current_resource
    aws_access_key_id = new_resource.aws_access_key_id || node['galoshes']['aws_access_key_id']
    aws_secret_access_key = new_resource.aws_secret_access_key || node['galoshes']['aws_secret_access_key']
    @service = Fog::AWS::ELB.new(:aws_access_key_id => aws_access_key_id, :aws_secret_access_key => aws_secret_access_key, :region => new_resource.region)
    @collection = Fog::AWS::ELB::LoadBalancers.new(:service => @service)
    @current_resource = @collection.new(:id => new_resource.name, :service => @service)
    # puts "curr: #{@current_resource}"
    @current_resource.reload
    # puts "curr.reload: #{@current_resource}"
    @exists = !(@current_resource.created_at.nil?)
    if @exists
    end

    @current_resource
  end

  def action_create
    Chef::Log.debug("new_resource: #{new_resource.inspect}")

    unless @exists
      converge_by("create #{resource_str}") do
        create_attributes = [:id, :availability_zones, :security_groups, :scheme, :listeners, :subnet_ids, :health_check]
        create_attributes.each do |attr|
          value = new_resource.send(attr)
          Chef::Log.debug("attr: #{attr} value: #{value} nil? #{value.nil?}")
          @current_resource.send("#{attr}=", value) unless value.nil?
        end
        Chef::Log.debug("current_resource before save: #{current_resource}")

        result = @current_resource.save
        Chef::Log.debug("create as result: #{result}")
        @exists = true

        read_only_attributes = [:created_at, :dns_name, :instances]
        read_only_attributes.each do |attr|
          value = @current_resource.send(attr)
          Chef::Log.debug("attr: #{attr} value: #{value} nil? #{value.nil?}")
          new_resource.send(attr, value) unless value.nil?
        end

        new_resource.updated_by_last_action(true)

      end
    end
  end
end
