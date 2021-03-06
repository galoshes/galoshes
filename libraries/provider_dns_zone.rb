require_relative 'provider_base'
require_relative 'service_dns'

class Chef::Provider::GaloshesDnsZone < Chef::Provider::GaloshesBase
  include Galoshes::DeleteMixin
  include Galoshes::DnsService

  attr_reader :collection

  def load_current_resource
    require 'fog'
    require 'fog/aws/models/dns/zones'

    @collection = Fog::DNS::AWS::Zones.new(:service => service)
    all = @collection.all
    @current_resource = all.find { |zone| zone.domain == new_resource.domain }

    @exists = !(@current_resource.nil?)
    Chef::Log.debug("#{resource_str} current_resource: #{@current_resource} exists: #{@exists}")

    if @exists
      new_resource.id(@current_resource.id)
    end

    @current_resource
  end

  def action_create
    converge_unless(@exists, "create #{resource_str}") do
      @current_resource = Fog::DNS::AWS::Zone.new(:service => service)
      create_attributes = [:domain, :description, :nameservers]
      copy_attributes(create_attributes)
      Chef::Log.debug("current_resource before save: #{current_resource}")

      result = @current_resource.save
      Chef::Log.debug("create as result: #{result}")
      @exists = true
      new_resource.id(@current_resource.id)
      new_resource.updated_by_last_action(true)
    end
  end

  def action_update
    if @exists
      filtered_options = [:description]
      Chef::Log.debug("filtered_options: #{filtered_options}")
      converged = true
      filtered_options.each do |attr|
        current_value = @current_resource.send(attr)
        new_value = new_resource.send(attr)
        if !(new_value.nil?) && (current_value != new_value)
          converged = false
          converge_by("Updating #{resource_str}.#{attr}") do
            @current_resource.send("#{attr}=", new_value)
          end
        end
        Chef::Log.debug("checking #{attr} cur: #{current_value} new: #{new_value} converged: #{converged}")
      end

      unless converged
        converge_by("Updating #{resource_str}") do
          @current_resource.update
          new_resource.updated_by_last_action(true)
        end
      end
    end
  end
end
