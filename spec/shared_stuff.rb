shared_context 'common stuff' do
  let(:log) { Logger.new(STDOUT).tap { |l| l.level = Logger::INFO } }
  let(:node) do
    node = Chef::Node.new
    # node.automatic['platform'] = 'ubuntu'
    # node.automatic['platform_version'] = '12.04'
    node.normal['galoshes']['aws_access_key_id'] = 'fake_access_key'
    node.normal['galoshes']['aws_secret_access_key'] = 'fake_secret_key'
    node
  end
  let(:events_formatter) { Chef::Formatters::Minimal.new(nil, nil) }
  let(:events_dispatcher) { Chef::EventDispatch::Dispatcher.new(events_formatter) }
  let(:run_context) { Chef::RunContext.new(node, {}, events_dispatcher) }
  let(:updates) { events_formatter.updates_by_resource[resource.name] }

  let(:existing_zone) do
    resource = Chef::Resource::GaloshesDnsZone.new('existing.fake.domain.com.')
    provider = Chef::Provider::GaloshesDnsZone.new(resource, run_context)
    provider.load_current_resource
    provider.action_create
    # puts "existing_zone: #{resource.inspect}"
    resource
  end

  let(:existing_dns_record) do
    resource = Chef::Resource::GaloshesDnsRecord.new('existing_subdomain')
    resource.zone(existing_zone)
    resource.type('A')
    resource.ttl(60)
    resource.value(['10.0.0.1'])
    provider = Chef::Provider::GaloshesDnsRecord.new(resource, run_context)
    provider.load_current_resource
    provider.action_create
    # puts "existing_dns_record: #{resource.inspect}"
    resource
  end

  # defines security groups as follows
  # :existing_security_group_#{name}
  def self.security_group(name)
    let("existing_security_group_#{name}".to_sym) do
      resource = Chef::Resource::GaloshesSecurityGroup.new("existing security group #{name}")
      resource.description("existing security group #{name}")
      resource.ip_permissions([])
      provider = Chef::Provider::GaloshesSecurityGroup.new(resource, run_context)
      provider.load_current_resource
      provider.action_create
      # puts "existing_sec_group: #{existing_security_group.inspect}"
      resource
    end
  end
  security_group('a')
  security_group('b')
  security_group('c')

  let(:existing_load_balancer) do
    resource = Chef::Resource::GaloshesLoadBalancer.new('existing load balancer')
    resource.security_groups([])
    resource.subnet_ids([])
    provider = Chef::Provider::GaloshesLoadBalancer.new(resource, run_context)
    provider.load_current_resource
    provider.action_create
    resource
  end

  let(:existing_launch_configuration) do
    resource = Chef::Resource::GaloshesLaunchConfiguration.new('existing launch configuration')
    resource.image_id('ami-123')
    resource.instance_type('m3.large')
    resource.user_data('existing user data')
    provider = Chef::Provider::GaloshesLaunchConfiguration.new(resource, run_context)
    provider.load_current_resource
    provider.action_create
    resource
  end

  let(:existing_dhcp_options) do
    resource = Chef::Resource::GaloshesDhcpOptions.new('existing dhcp options')
    provider = Chef::Provider::GaloshesDhcpOptions.new(resource, run_context)
    provider.load_current_resource
    provider.action_create
    resource
  end

  let(:existing_vpc) do
    resource = Chef::Resource::GaloshesVpc.new('existing vpc')
    resource.dhcp_options_id(existing_dhcp_options.id)
    resource.cidr_block('10.0.0.0/16')
    provider = Chef::Provider::GaloshesVpc.new(resource, run_context)
    provider.load_current_resource
    provider.action_create
    resource
  end

  let(:existing_subnet) do
    resource = Chef::Resource::GaloshesSubnet.new('existing subnet')
    resource.vpc_id(existing_vpc.id)
    resource.cidr_block('10.0.99.0/24')
    provider = Chef::Provider::GaloshesSubnet.new(resource, run_context)
    provider.load_current_resource
    provider.action_create
    resource
  end

  let(:existing_server) do
    resource = Chef::Resource::GaloshesServer.new('existing_server')
    provider = Chef::Provider::GaloshesServer.new(resource, run_context)
    provider.load_current_resource
    provider.action_create
    resource
  end

  let(:existing_autoscaling_group) do
    resource = Chef::Resource::GaloshesAutoscalingGroup.new('existing autoscaling group')
    resource.availability_zones(['us-east-1'])
    resource.launch_configuration(existing_launch_configuration)
    provider = Chef::Provider::GaloshesAutoscalingGroup.new(resource, run_context)
    provider.load_current_resource
    provider.action_create
    resource
  end

  before do
    Fog.mock!
    Fog::Mock.reset
    existing_zone
    existing_dns_record
    existing_security_group_a
    existing_security_group_b
    existing_security_group_c
    existing_load_balancer
    existing_launch_configuration
    existing_dhcp_options
    existing_vpc
    existing_subnet
    existing_server
    existing_autoscaling_group
  end
end
