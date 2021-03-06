require_relative 'service_compute'

class Chef::Provider::GaloshesSubnet < Chef::Provider::GaloshesBase
  include Galoshes::ComputeService

  def load_current_resource
    @collection = Fog::Compute::AWS::Subnets.new(:service => service)

    Chef::Log.info("vpc_id: #{new_resource.vpc_id}")

    if new_resource.subnet_id
      @current_resource = @collection.get(new_resource.subnet_id)
      @exists = !(@current_resource.nil?)
    else
      subnets = @collection.all('tag:Name' => new_resource.name, 'vpc-id' => new_resource.vpc_id)

      if subnets.size == 1
        Chef::Log.debug("Found #{resource_str}.")
        @current_resource = subnets[0]
        @exists = true
        Chef::Log.debug("Found cur: #{@current_resource.to_json}")
      else
        Chef::Log.debug("Couldn't find #{resource_str}. Found #{subnets.size}")
        @exists = false
      end
    end
    @current_resource = @collection.new unless @exists
  end

  def action_create
    Chef::Log.debug("new_resource: #{new_resource}")

    converge_unless(@exists, "create #{resource_str}") do
      create_attributes = [:cidr_block, :availability_zone, :vpc_id, :tag_set]
      copy_attributes(create_attributes)
      Chef::Log.debug("current_resource before save: #{current_resource}")
      result = @current_resource.save
      @current_resource.reload
      Chef::Log.debug("create as result: #{result} after save #{current_resource}")
    end
    verify_attribute(:tag_set) do
      service.create_tags(@current_resource.subnet_id, new_resource.tag_set) unless Fog.mocking?
    end
  end
end
