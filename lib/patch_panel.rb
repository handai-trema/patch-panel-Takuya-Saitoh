# Software patch-panel.
class PatchPanel < Trema::Controller
  def start(_args)
    @patch = Hash.new([])
    @mirror = Hash.new([])
    logger.info 'PatchPanel started.'
  end

  def switch_ready(dpid)
    @patch[dpid].each do |port_a, port_b|
      delete_flow_entries dpid, port_a, port_b
      add_flow_entries dpid, port_a, port_b
    end
    @mirror[dpid].each do |port_a, port_b|
      add_mirror_entries dpid, port_a, port_b
    end
  end

  def create_patch(dpid, port_a, port_b)
    add_flow_entries dpid, port_a, port_b
    @patch[dpid] << [port_a, port_b].sort
  end

  def delete_patch(dpid, port_a, port_b)
    delete_flow_entries dpid, port_a, port_b
    @patch[dpid].delete([port_a, port_b].sort)
  end
  
  def create_mirror(dpid, port_a, port_b)
    add_mirror_entries dpid, port_a, port_b
    @mirror[dpid] << [port_a, port_b].sort
  end
  
  def show_list(dpid)
  	puts '--patch list--'
  	@patch[dpid].each do |port_a, port_b|
  		print "#{port_a} and #{port_b}\n"
  	end
  	puts '--mirror list--'
  	@mirror[dpid].each do |port_a, port_b|
  		print "#{port_a} and #{port_b}\n"
  	end
  end

  private

  def add_flow_entries(dpid, port_a, port_b)
    send_flow_mod_add(dpid,
                      match: Match.new(in_port: port_a),
                      actions: SendOutPort.new(port_b))
    send_flow_mod_add(dpid,
                      match: Match.new(in_port: port_b),
                      actions: SendOutPort.new(port_a))
  end

  def delete_flow_entries(dpid, port_a, port_b)
    send_flow_mod_delete(dpid, match: Match.new(in_port: port_a))
    send_flow_mod_delete(dpid, match: Match.new(in_port: port_b))
  end
  
  # port_a: ミラーリング元, port_b: ミラーリング先, port_c: port_a　の通信相手
  def add_mirror_entries(dpid, port_a, port_b)
  	port_c = 0
  	@patch[dpid].each do |a, b|
  		if a == port_a then
  			port_c = b
  		elsif b == port_a then
  			port_c = a
  		end
  	end 	
  	if port_c != 0 then
  		delete_flow_entries(dpid, port_a, port_c)
  		send_flow_mod_add(dpid,
  											match: Match.new(in_port: port_a),
  											actions: [SendOutPort.new(port_b),
  																SendOutPort.new(port_c)])
  	  send_flow_mod_add(dpid,
  											match: Match.new(in_port: port_c),
  											actions: [SendOutPort.new(port_a),
  																SendOutPort.new(port_b)])
  	end
  end
  
end
