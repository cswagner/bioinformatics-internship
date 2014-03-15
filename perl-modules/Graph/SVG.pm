#--------------------------------------------------
#   File:        SVG.pm
#   Author:      Chris Wagner
#   Description: provides methods for graphing 
#                a set of sets with a set of edges
#                of varying types in SVG format
#   Date:        8/20/10
#--------------------------------------------------

package Graph::SVG;

use Graph;
use GD::SVG;
use GD::Polyline;

my $DEFAULT_STYLE = "C:\\Users\\Chris\\Documents\\Programming\\Summer_2010\\Graph_Visualizer\\Graph\\svg_default.style";

my %style = ();

#--------------------------------------------------
#   Subroutine:  loadStyle
#   Description: loads stylesheet to be accessed
#		         when drawing the graph
#   Parameters:  $filepath - location of stylesheet
#   Return:      none
#--------------------------------------------------
sub loadStyle {
	my ($filepath) = @_;
	
	if (not $filepath) {
		$filepath = $DEFAULT_STYLE;
	}
	
	unless (-e $filepath) {
		print STDERR "Cannot find $filepath\n";
		exit 1;
	}
		
	unless (open (FILE, $filepath)) {
		print STDERR "Cannot open $filepath\n";
		exit 1;
	}
	
	my $line_count = 0;
	my $object = 'blank';
	my $name = "";
	
	foreach my $line (<FILE>) {
		$line_count++;
		
		chomp $line;

		$line =~ s/\s//ig;
		$line =~ s/#.*//ig;
		
		if ($line eq "set:") {
			$object = 'set';
		}elsif ($line eq "edge:") {
			$object = 'edge';
		}elsif ($line eq "") {
			$object = 'blank';
		}else {
			if ($object eq 'set') {
				my @pair = split (/:/, $line);
				if ($pair[0] eq "name") {
					$name = $pair[1];
				}else {
					$style{'sets'} -> {$name} -> {$pair[0]} = $pair[1];
				}
			}elsif ($object eq 'edge') {
				my @pair = split (/:/, $line);
				if ($pair[0] eq "name") {
					$name = $pair[1];
				}else {
					$style{'edges'} -> {$name} -> {$pair[0]} = $pair[1];
				}
			}else {
				print STDERR "Illegal identifier on line $line_count from $filepath\n";
				exit 1;
			}
		}
	}
	
	close FILE;
}

sub get_edgeColor {
	my ($edge_type) = @_;
	
	my $edges_ref = $style{'edges'};
	my %edges = %$edges_ref;
	my $rgb = $edges{$edge_type} -> {'color'};
	my @rgb_str = split (/[()]/ig, $rgb);
	@rgbs = split (/,/, $rgb_str[1]);
	return @rgbs;
}

sub get_nodeFillColor {
	my ($set_name) = @_;
	
	my $sets_ref = $style{'sets'};
	my %sets = %$sets_ref;
	return $sets{$set_name} -> {'node-fill'};
}

sub get_nodeStrokeColor {
	my ($set_name) = @_;
	
	my $sets_ref = $style{'sets'};
	my %sets = %$sets_ref;
	return $sets{$set_name} -> {'node-stroke-color'};
}

sub get_nodeStrokeWidth {
	my ($set_name) = @_;
	
	my $sets_ref = $style{'sets'};
	my %sets = %$sets_ref;
	return $sets{$set_name} -> {'node-stroke-width'};
}

sub get_nodeRadius {
	my ($set_name) = @_;
	
	my $sets_ref = $style{'sets'};
	my %sets = %$sets_ref;
	return $sets{$set_name} -> {'node-radius'};
}

#--------------------------------------------------
#   Subroutine:  toSVG
#   Description: creates an interactive SVG
#		         graph
#   Parameters:  $filename - desired output filename
#		         $stylesheet - location of stylesheet
#				               to use
#   Return:      none
#--------------------------------------------------
sub toSVG {
	my ($filename, $stylesheet) = @_;

	#retrieve nodes
	my $node_sets_ref = Graph::get_Nodes ();
	my @node_sets = @$node_sets_ref;
	my $set_names_ref = Graph::get_setNames ();
	my @set_names = @$set_names_ref;
	
	#retrieve edges
	my $edges_ref = Graph::get_Edges ();
	my @edges_set = @$edges_ref;
	
	#count the number of nodes (including node spaces) that have to be drawn
	my $num_nodes = 0;
	foreach my $node_set_ref (@node_sets) {
		$num_nodes += scalar @$node_set_ref;
	}
	$num_nodes += scalar @node_sets * Graph::get_setSpaces ();
	
	if ($num_nodes <= 0) {
		print STDERR "ERROR: No data given\n";
		exit;
	}

	Graph::SVG::loadStyle ($stylesheet);

	my $graph_cushion = 25;
	my $width = (($num_nodes / 2) * Graph::get_nodeSpace ()) + (2 * $graph_cushion);
	my $height = $width;
	
	if($width < 300) {
		$width = 300;
	}
	if($height < 300) {
		$height = 300;
	}
	
	my $clip_y = $height / 3;
	my $clip_height = 2 * $clip_y;
	
	my $graph_x = $width / 2;
	my $graph_y = $height / 2;
	my $graph_radius = ($width / 2) - $graph_cushion;

	unless (open(FILE, ">$filename")) {
		print STDERR "Cannot open $filename\n";
		exit 1;
	}
	my $file_ref = \*FILE;

	print FILE <<END_SVG;
<?xml version="1.0" standalone="no"?>
<svg xmlns="http://www.w3.org/2000/svg" version="1.1" 
	xmlns:xlink="http://www.w3.org/1999/xlink"
	width="$width" height="$height"
	id = "myimage">
	
	<defs>
		<radialGradient id = "bg_circle_fill" cx = "50%" cy = "50%" r = "50%" fx = "50%" fy = "50%">
			<stop stop-color = "rgb(255, 255, 255)" offset = "0%" />
			<stop stop-color = "rgb(225, 225, 225)" offset = "90%" />
			<stop stop-color = "rgb(100, 100, 100)" offset = "100%" />
		</radialGradient>
		<filter id = "node_blur">
			<feGaussianBlur stdDeviation="2" />
		</filter>
	</defs>
	
	<script type = "text/javascript"><![CDATA[
		var legend_open = false;
		var legend_items_position = 0;
		var current_node = null;
		var edges_info = new Array();
		var info_box_edge_cursor = 0;
	
		function node_onmouseover(evt) {
			var node_group = document.getElementById("nodes");
			var node = evt.target;
			var node_id = node.getAttribute("id");
			var node_id_vals = node_id.split(" ");
			var nodes = node_group.getElementsByTagName("circle");
			var edges = node_group.getElementsByTagName("polyline");
			var end_nodes = new Array();
			
			for(var k = 0; k < edges.length; ++k) {
				var node_edges = edges[k].getAttribute("desc");
				var node_edges_vals = node_edges.split(" ");
				
				if(node_edges_vals[2] == node_id_vals[0]) {
					if(node_edges_vals[3] == node_id_vals[1]) {
						var end_node = new Array();
						end_node[0] = node_edges_vals[0];
						end_node[1] = node_edges_vals[1];
						end_nodes.push(end_node);
					}else {
						edges[k].setAttribute("filter", "url(#node_blur)");
						edges[k].setAttribute("opacity", .25);
					}
				}else if(node_edges_vals[0] == node_id_vals[0]) {
					if(node_edges_vals[1] == node_id_vals[1]) {
						var end_node = new Array();
						end_node[0] = node_edges_vals[2];
						end_node[1] = node_edges_vals[3];
						end_nodes.push(end_node);
					}else {
						edges[k].setAttribute("filter", "url(#node_blur)");
						edges[k].setAttribute("opacity", .25);
					}
				}else {
					edges[k].setAttribute("filter", "url(#node_blur)");
					edges[k].setAttribute("opacity", .25);
				}
			}

			var selected = false;
			for(var i = 0; i < nodes.length; ++i) {
				selected = false;
				if(nodes[i] === node) {
					selected = true;
				}else {
					var current_node_id = nodes[i].getAttribute("id");
					var current_node_id_vals = current_node_id.split(" ");
					var current_node_set = current_node_id_vals[0];
					var current_node_num = current_node_id_vals[1];
					for(var j = 0; j < end_nodes.length; ++j) {
						var end_node_set = end_nodes[j][0];
						var end_node_num = end_nodes[j][1];
						if(current_node_num === end_node_num && current_node_set === end_node_set) {
							selected = true;
						}
					}
					if(!selected) {
						nodes[i].setAttribute("filter", "url(#node_blur)");
						nodes[i].setAttribute("opacity", .25);
					}
				}
			}
		}
		function node_onmouseout(evt) {
			var node_group = document.getElementById("nodes");
			var node = evt.target;
			var nodes = node_group.getElementsByTagName("circle");
			var edges = node_group.getElementsByTagName("polyline");
			
			for(var i = 0; i < nodes.length; ++i) {
				if(nodes[i] !== node) {
					nodes[i].setAttribute("filter","");
					nodes[i].setAttribute("opacity", 1);
				}
			}
			
			for(var k = 0; k < edges.length; ++k) {
				edges[k].setAttribute("filter", "");
				edges[k].setAttribute("opacity", 1);
			}
		}
		function node_onmouseclick(evt) {
			var node_group = document.getElementById("nodes");
			var node = evt.target;
			var node_id = node.getAttribute("id");
			var node_id_vals = node_id.split(" ");
			var node_name = node.getAttribute("desc");
			var nodes = node_group.getElementsByTagName("circle");
			var edges = node_group.getElementsByTagName("polyline");
			var end_nodes = new Array();
			var node_info_box = document.getElementById("info_box");
			node_info_box.setAttribute("opacity", 1);
			info_box_edge_cursor = 0;
			edges_info = new Array();
			var up_btn = document.getElementById("info_box_up_btn");
			var down_btn = document.getElementById("info_box_down_btn");
			
			//move connector
			var connector_box = document.getElementById("info_box_connector_box");
			var connector_box_end = document.getElementById("info_box_connector_box_end");
			var connector_arrow = document.getElementById("info_box_connector_arrow");
			var info_box_bg = document.getElementById("info_box_bg");
			var info_box_bg_x = parseFloat(info_box_bg.getAttribute("x"));
			var info_box_bg_y = parseFloat(info_box_bg.getAttribute("y"));
			var info_box_bg_width = parseFloat(info_box_bg.getAttribute("width"));
			var info_box_bg_height = parseFloat(info_box_bg.getAttribute("height"));
			var node_x = parseFloat(node.getAttribute("cx"));
			var node_y = parseFloat(node.getAttribute("cy"));
			var new_x = 0;
			var new_y = 0;
			if(node_x > $graph_x) {
				//move connector to right
				new_x = info_box_bg_x + info_box_bg_width - 5;
				connector_box.setAttribute("cx", new_x);
				connector_arrow.setAttribute("x1", new_x);
			}else {
				//move connector to left
				new_x = info_box_bg_x + 5;
				connector_box.setAttribute("cx", new_x);
				connector_arrow.setAttribute("x1", new_x);
			}
			if(node_y > $graph_y) {
				//move connector to bottom
				new_y = info_box_bg_y + info_box_bg_height - 5;
				connector_box.setAttribute("cy", new_y);
				connector_arrow.setAttribute("y1", new_y);
			}else {
				//move connector to top
				new_y = info_box_bg_y + 5;
				connector_box.setAttribute("cy", new_y);
				connector_arrow.setAttribute("y1", new_y);
			}
			var new_r = parseFloat(node.getAttribute("r"))+ 5;
			connector_box_end.setAttribute("r", new_r);
			connector_box_end.setAttribute("cx", node_x);
			connector_box_end.setAttribute("cy", node_y);
			
			var x_diff = node_x - new_x;
			var y_diff = node_y - new_y;
			var diff_length = Math.sqrt((x_diff * x_diff) + (y_diff * y_diff));
			var highlight_x = node_x - (new_r * (x_diff / diff_length));
			var highlight_y = node_y - (new_r * (y_diff / diff_length));
			connector_arrow.setAttribute("x2", highlight_x);
			connector_arrow.setAttribute("y2", highlight_y);


			if(current_node === node) {
				//close info box
				var trans = "translate($width, 0)";
				node_info_box.setAttribute("transform", trans);
				current_node = null;
			}else {
				if(current_node === null) {
					//show info box
					var trans = "translate(0, 0)";
					node_info_box.setAttribute("transform", trans);
				}
				
				current_node = node;
				
				//move connector
				
				
				for(var k = 0; k < edges.length; ++k) {
					var node_edges = edges[k].getAttribute("desc");
					var node_edges_vals = node_edges.split(" ");
						
					if(node_edges_vals[2] == node_id_vals[0]) {
						if(node_edges_vals[3] == node_id_vals[1]) {
							var end_node = new Array();
							end_node[0] = node_edges_vals[0];
							end_node[1] = node_edges_vals[1];
							var id = end_node[0] + " " + end_node[1];
							var act_node = document.getElementById(id);
							var act_node_name = act_node.getAttribute("desc");
							end_node[2] = act_node_name;
							end_node[3] = node_edges_vals[4];
							var linestyle = edges[k].getAttribute("style");
							var linestyle_attr = linestyle.split(";");
							var stroke_width = linestyle_attr[4];
							var stroke_width_vals = stroke_width.split(": ");
							var edge_weight = stroke_width_vals[1];
							end_node[4] = edge_weight;
							end_nodes.push(end_node);
						}
					}else if(node_edges_vals[0] == node_id_vals[0]) {
						if(node_edges_vals[1] == node_id_vals[1]) {
							var end_node = new Array();
							end_node[0] = node_edges_vals[2];
							end_node[1] = node_edges_vals[3];
							var id = end_node[0] + " " + end_node[1];
							var act_node = document.getElementById(id);
							var act_node_name = act_node.getAttribute("desc");
							end_node[2] = act_node_name;
							end_node[3] = node_edges_vals[4];
							var linestyle = edges[k].getAttribute("style");
							var linestyle_attr = linestyle.split(";");
							var stroke_width = linestyle_attr[4];
							var stroke_width_vals = stroke_width.split(": ");
							var edge_weight = stroke_width_vals[1];
							end_node[4] = edge_weight;
							end_nodes.push(end_node);
						}
					}
				}
				
				//add text to info box
				var info_name_txt = document.getElementById("info_box_name_txt").firstChild;
				var info_end_node_txt = document.getElementById("info_box_end_node_txt").firstChild;
				var info_edge_type_txt = document.getElementById("info_box_edge_type_txt").firstChild;
				var info_edge_weight_txt = document.getElementById("info_box_edge_weight_txt").firstChild;
				var info_fraction = document.getElementById("info_box_fraction_txt");
				var info_fraction_txt = info_fraction.firstChild;
				info_name_txt.nodeValue = node_name;
					
				if(end_nodes.length > 0) {
					if(end_nodes.length > 1) {
						up_btn.setAttribute("visibility", "visible");
						down_btn.setAttribute("visibility", "visible");
						info_fraction.setAttribute("visibility", "visible");
					}else {
						up_btn.setAttribute("visibility", "hidden");
						down_btn.setAttribute("visibility", "hidden");
						info_fraction.setAttribute("visibility", "hidden");
					}
					info_end_node_txt.nodeValue = ". . . . . Edge to: " + end_nodes[0][2];
					info_edge_type_txt.nodeValue = ". . . . . Type: " + end_nodes[0][3];
					info_edge_weight_txt.nodeValue = ". . . . . Weight: " + end_nodes[0][4];
						
					for(var l = 0; l < end_nodes.length; ++l) {
						var edge_info = new Array();
						edge_info[0] = end_nodes[l][2];
						edge_info[1] = end_nodes[l][3];
						edge_info[2] = end_nodes[l][4];
						edges_info.push(edge_info);
					}
					
					info_fraction_txt.nodeValue = (info_box_edge_cursor + 1) + " / " + edges_info.length;
				}else {
					info_end_node_txt.nodeValue = ". . . . . no edges"
					info_edge_type_txt.nodeValue = "";
					info_edge_weight_txt.nodeValue = "";
					up_btn.setAttribute("visibility", "hidden");
					down_btn.setAttribute("visibility", "hidden");
					info_fraction.setAttribute("visibility", "hidden");
				}
			}
		}
		
		function legend_onmouseover(evt) {
			var leg = document.getElementById("legend");
			var leg_runner = document.getElementById("legend_runner");
			var leg_tab = document.getElementById("legend_tab");
			var leg_tab_text = document.getElementById("legend_tab_text");
			leg_tab_text.setAttribute("fill", "rgb(0, 0, 0)");
			leg_runner.setAttribute("fill", "rgb(200, 200, 200)");
			leg_tab.setAttribute("fill", "rgb(200, 200, 200)");
			leg.setAttribute("opacity", 1);
		}
		function legend_onmouseout(evt) {
			var leg_runner = document.getElementById("legend_runner");
			var leg_tab = document.getElementById("legend_tab");
			var leg_tab_text = document.getElementById("legend_tab_text");
			leg_tab_text.setAttribute("fill", "rgb(255, 255, 255)");
			leg_runner.setAttribute("fill", "rgb(100, 100, 100)");
			leg_tab.setAttribute("fill", "rgb(100, 100, 100)");
			if(legend_open) {
				var leg = document.getElementById("legend");
				leg.setAttribute("opacity", .1);
			}
		}
		function legend_click(evt) {
			var leg_up_btn = document.getElementById("legend_up_btn");
			var leg_down_btn = document.getElementById("legend_down_btn");
			var targ = evt.target;
			if(targ === leg_up_btn || targ === leg_down_btn) {
				
			}else {
				var leg = document.getElementById("legend");
				var trans_distance = 0;
				var leg_tab = document.getElementById("legend_tab");
				var leg_tab_text = document.getElementById("legend_tab_text");
				var leg_items = document.getElementById("legend_items");
				
				if(legend_open) {
						trans_distance = 0;
						legend_open = false;
						leg_tab.setAttribute("transform", "translate(0, 0)");
						leg_tab_text.setAttribute("transform", "translate(0, 0)");
						leg_items.setAttribute("transform", "translate(0, 0)");
				}else {
					var leg_runner = document.getElementById("legend_runner");
					var h = leg_runner.getAttribute("height");
					if(h >= $height) {
						trans_distance = -$height;
						leg_tab.setAttribute("transform", "translate(0, 18)");
						leg_tab_text.setAttribute("transform", "translate(0, 15)");
					}else {
						trans_distance = -h;
					}
					legend_open = true;
				}
				var trans = "translate(0, " + trans_distance + ")";
				leg.setAttribute("transform", trans);
			}
		}
		function legend_btn_onmouseover(evt) {
			var btn = evt.target;
			btn.setAttribute("fill", "rgb(200, 200, 200)");
		}
		function legend_btn_onmouseout(evt) {
			var btn = evt.target;
			btn.setAttribute("fill", "rgb(100, 100, 100)");
		}
		function legend_up_btn_click(evt) {
			if(legend_items_position > 0) {
				legend_items_position--;
				var leg_items = document.getElementById("legend_items");
				var trans_distance = -(legend_items_position * 20);
				var trans = "translate(0, " + trans_distance + ")";
				leg_items.setAttribute("transform", trans);
			}
		}
		function legend_down_btn_click(evt) {
			var leg_runner = document.getElementById("legend_runner");
			var h = leg_runner.getAttribute("height");
			var critical_pos = (h - $height) / 20;
			if(legend_items_position < critical_pos) {
				legend_items_position++;
				var leg_items = document.getElementById("legend_items");
				var trans_distance = -(legend_items_position * 20);
				var trans = "translate(0, " + trans_distance + ")";
				leg_items.setAttribute("transform", trans);
			}
		}
		function info_box_onmouseover(evt) {
			var node_info_box = document.getElementById("info_box");
			node_info_box.setAttribute("opacity", 1);
		}
		function info_box_onmouseout(evt) {
			var node_info_box = document.getElementById("info_box");
			node_info_box.setAttribute("opacity", .1);
		}
		function info_box_onclick(evt) {
			var up_btn = document.getElementById("info_box_up_btn");
			var down_btn = document.getElementById("info_box_down_btn");
			var targ = evt.target;
			
			if(targ === up_btn || targ === down_btn) {
			
			}else {
				var node_info_box = document.getElementById("info_box");
				//close info box
				var trans = "translate($width, 0)";
				node_info_box.setAttribute("transform", trans);
				node_info_box.setAttribute("opacity", 1);
				edges_info = new Array();
				info_box_edge_cursor = 0;
				current_node = null;
			}
		}
		function info_box_btn_onclick(evt) {
			if(edges_info.length > 0) {
				var up_btn = document.getElementById("info_box_up_btn");
				var down_btn = document.getElementById("info_box_down_btn");
				var targ = evt.target;
			
				if(targ === up_btn) {
					if(info_box_edge_cursor > 0) {
						info_box_edge_cursor--;
					}
				}else if(targ === down_btn) {
					if(info_box_edge_cursor < edges_info.length - 1) {
						info_box_edge_cursor++;
					}
				}
				
				var info_end_node_txt = document.getElementById("info_box_end_node_txt").firstChild;
				var info_edge_type_txt = document.getElementById("info_box_edge_type_txt").firstChild;
				var info_edge_weight_txt = document.getElementById("info_box_edge_weight_txt").firstChild;
				var info_fraction_txt = document.getElementById("info_box_fraction_txt").firstChild;
				
				info_end_node_txt.nodeValue = ". . . . . Edge to: " + edges_info[info_box_edge_cursor][0];
				info_edge_type_txt.nodeValue = ". . . . . Type: " + edges_info[info_box_edge_cursor][1];
				info_edge_weight_txt.nodeValue = ". . . . . Weight: " + edges_info[info_box_edge_cursor][2];
				info_fraction_txt.nodeValue = (info_box_edge_cursor + 1) + " / " + edges_info.length;
			}
		}
		function info_box_btn_onmouseover(evt) {
			var btn = evt.target;
			btn.setAttribute("fill", "rgb(255, 255, 255)");
		}
		function info_box_btn_onmouseout(evt) {
			var btn = evt.target;
			btn.setAttribute("fill", "rgb(0, 0, 0)");
		}
	]]></script>
	
	<g id = "elements">
	<circle cx = "$graph_x" cy = "$graph_y" r = "$graph_radius" fill = "url(#bg_circle_fill)" opacity = "0.5" />
	<g id = "nodes" opacity = "1">
END_SVG
	
	my $angle_slice = 6.28 / $num_nodes;
	
	#draw edges
	my $node_pos = 0;
	my $edge_count = 0;
	my $angle;
	
	my $img = GD::SVG::Image->new ($width,$height, 1);
	my $white = $img -> colorAllocate (255, 255, 255);
	
	foreach my $edge (@edges_set) {
		#find start node
		$angle = $angle_slice;
		$node_pos = 0;
		my ($set, $index) = Graph::get_edgeStart($edge_count);
    
		for (my $i = 0; $i < $set; ++$i) {
			my $list_ref = $node_sets[$i];
			my @list = @$list_ref;
			$node_pos += scalar @list + 1;
		}
		$node_pos += $index;
		$angle += $angle_slice * $node_pos;
    
		my $n1_x = $graph_x - ($graph_radius * cos ($angle));
		my $n1_y = $graph_y + ($graph_radius * sin ($angle));
    
		#find end node
		$node_pos = 0;
		$angle = $angle_slice;
		my ($set, $index) = Graph::get_edgeEnd($edge_count);
    
		for (my $i = 0; $i < $set; ++$i) {
			my $list_ref = $node_sets[$i];
			my @list = @$list_ref;
			$node_pos += scalar @list + 1;
		}
		$node_pos += $index;
		$angle += $angle_slice * $node_pos;
    
		my $n2_x = $graph_x - ($graph_radius * cos ($angle));
		my $n2_y = $graph_y + ($graph_radius * sin ($angle));
		
		#draw edge
		if (Graph::get_edgeWeight($edge_count) > 0) {
			my @rgb = Graph::SVG::get_edgeColor (Graph::get_edgeType ($edge_count));
			my $edge_color = $img -> colorAllocate (@rgb);
			
			$img -> setThickness (Graph::get_edgeWeight($edge_count));
			
			my $arc = new GD::Polyline;
			$arc -> addPt ($n1_x, $n1_y);
			$arc -> addPt ((($width/2) + (($n1_x + $n2_x)/2))/2,  (($width/2) + (($n1_y + $n2_y )/2))/2);
			$arc -> addPt ($n2_x, $n2_y);
			my $spline = $arc -> addControlPoints -> toSpline;
			
			$img -> polydraw ($spline, $edge_color);
		
			$img -> setThickness (1);
		
			$edge_count++;
		}
	}
	
	#add properties to edge
	my $edges_image = $img -> svg ();
	$edge_count = 0;
	while ($edges_image =~ /<polyline.*\/>/ig) {
		my $edge_str = $&;
		chop $edge_str;
		chop $edge_str;
		chop $edge_str;
		my ($start_set, $start_node) = Graph::get_edgeStart($edge_count);
		my ($end_set, $end_node) = Graph::get_edgeEnd($edge_count);
		my $type = Graph::get_edgeType($edge_count);
		$edge_str = "$edge_str desc = '$start_set $start_node $end_set $end_node $type' opacity = '1' />\n";
		print FILE $edge_str;
		$edge_count++;
	}
	
	#draw nodes
	my $set_counter = 0;
	$angle = $angle_slice;
	foreach my $node_set_ref (@node_sets) {
		my $set_name = $set_names[$set_counter];
		my @node_set = @$node_set_ref;
		my $node_counter = 0;
		foreach my $node (@node_set) {
			my $xpos = $graph_x - ($graph_radius * cos ($angle));
			my $ypos = $graph_y + ($graph_radius * sin ($angle));
			
			Graph::SVG::drawNode ($xpos, $ypos, $node, $set_name, $set_counter, $node_counter, $file_ref);
			$angle += $angle_slice;
			$node_counter++;
		}
		$angle += $angle_slice;
		$set_counter++;
	}
	print FILE "</g>\n";	#end nodes
	print FILE "</g>\n";	#end elements

	#draw node information popup offscreen
	my $text_padding = 5;
	my $info_width = 2 * ($width / 3);
	my $info_height = $width / 3;
	my $info_x = $graph_x - ($info_width / 2);
	my $info_y = $graph_y - ($info_height / 2);
	my $info_text_x = $info_x + $text_padding + 20;
	my $info_text_y = $info_y + 22;
	my $info_text_y_step = abs (($info_height - 27) / 3);
	my $info_btn_x = $info_x + 5;
	my $info_btn_y = $info_y + ($info_height / 2) - 20;
	my $connector_box_x = $info_x + 5;
	my $connector_box_y = $info_y + 5;
	my $connector_box_rad = 10;
	print FILE "<g id = 'info_box' transform = 'translate($width, 0)' opacity = '1'
			 onmouseover = 'info_box_onmouseover(evt)'
			 onmouseout = 'info_box_onmouseout(evt)'
			 onclick = 'info_box_onclick(evt)'>\n";
	print FILE "	<rect
					id = 'info_box_bg' 
					x = '$info_x' 
					y = '$info_y'
					rx = '20'
					ry = '20'
					width = '$info_width' 
					height = '$info_height' 
					fill = 'rgb(100, 100, 100)' 
				/>\n";
	print FILE "	<text
					id = 'info_box_name_txt'
					x = '$info_text_x'
					y = '$info_text_y'
					font-family = 'Arial'
					font-size = '20'
					fill = 'rgb(255, 255, 255)'
				>
				NODE NAME
				</text>\n";
	$info_text_y += 22;
	print FILE "	<text
					id = 'info_box_end_node_txt'
					x = '$info_text_x'
					y = '$info_text_y'
					font-family = 'Arial'
					font-size = '12'
					fill = 'rgb(255, 255, 255)'
				>
				END NODE
				</text>\n";
	$info_text_y += $info_text_y_step;
	print FILE "	<text
					id = 'info_box_edge_type_txt'
					x = '$info_text_x'
					y = '$info_text_y'
					font-family = 'Arial'
					font-size = '12'
					fill = 'rgb(255, 255, 255)'
				>
				EDGE TYPE
				</text>\n";
	$info_text_y += $info_text_y_step;
	print FILE "	<text
					id = 'info_box_edge_weight_txt'
					x = '$info_text_x'
					y = '$info_text_y'
					font-family = 'Arial'
					font-size = '12'
					fill = 'rgb(255, 255, 255)'
				>
				EDGE WEIGHT
				</text>\n";
	$info_text_x += 2 * ($info_width / 3);
	print FILE "	<text
					id = 'info_box_fraction_txt'
					x = '$info_text_x'
					y = '$info_text_y'
					font-family = 'Arial'
					font-size = '14'
					fill = 'rgb(255, 255, 255)'
				>
				EDGE_CURSOR / NUM_EDGES
				</text>\n";
	print FILE "	<rect
					id = 'info_box_up_btn'
					x = '$info_btn_x'
					y = '$info_btn_y'
					width = '10'
					height = '10'
					cursor = 'pointer'
					onclick = 'info_box_btn_onclick(evt)'
					onmouseover = 'info_box_btn_onmouseover(evt)'
					onmouseout = 'info_box_btn_onmouseout(evt)'
					fill = 'rgb(0, 0, 0)'
				/>\n";
	$info_btn_y = $info_y + ($info_height / 2) + 10;
	print FILE "	<rect
					id = 'info_box_down_btn'
					x = '$info_btn_x'
					y = '$info_btn_y'
					width = '10'
					height = '10'
					cursor = 'pointer'
					onclick = 'info_box_btn_onclick(evt)'
					onmouseover = 'info_box_btn_onmouseover(evt)'
					onmouseout = 'info_box_btn_onmouseout(evt)'
					fill = 'rgb(0, 0, 0)'
				/>\n";
	print FILE "	<line 
					id = 'info_box_connector_arrow'
					x1 = '$connector_box_x' 
					x2 = '0' 
					y1 = '$connector_box_y' 
					y2 = '30' 
					stroke = 'rgb(100, 100, 100)' 
					stroke-width = '5' 					
				/>\n";			
	print FILE "	<circle
					id = 'info_box_connector_box'
					cx = '$connector_box_x'
					cy = '$connector_box_y'
					r = '$connector_box_rad'
					fill = 'rgb(255, 255, 255)'
					stroke = 'rgb(100, 100, 100)'
					stroke-width = '2'
				/>\n";
	print FILE "	<circle
					id = 'info_box_connector_box_end'
					cx = '$connector_box_x'
					cy = '$connector_box_y'
					r = '$connector_box_rad'
					fill = 'none'
					stroke = 'rgb(100, 100, 100)'
					stroke-width = '2'
				/>\n";
	print FILE "</g>\n";	#end info box popup

	#draw edge legend tab
	my $edges_ref = $style{'edges'};
	my %edges = %$edges_ref;
	
	my $edge_item_height = 20;
	my $legend_height = (scalar (keys %edges) * $edge_item_height) + (2 * $text_padding); 
	my $legend_y = $height - 3;
	my $tab_height = 15;
	my $tab_y = $legend_y - $tab_height;
	my $tab_width = 50;
	my $tab_x = $width - $tab_width;
	my $text_x = $tab_x + $text_padding;
	my $bg_width = $width - (2 * $text_padding);
	my $bg_height = $legend_height - $text_padding;
	print FILE "<g id = 'legend' opacity = '1' onclick = 'legend_click(evt)'
							 onmouseover = 'legend_onmouseover(evt)'
							 onmouseout = 'legend_onmouseout(evt)'>\n";
	print FILE "	<rect 
					id = 'legend_runner'
					x = '0' 
					y = '$legend_y' 
					width = '$width' 
					height = '$legend_height' 
					fill = 'rgb(100, 100, 100)'
					cursor = 'pointer'
				/>\n";
	print FILE "	<rect
					id = 'legend_bg'
					x = '$text_padding'
					y = '$height'
					width = '$bg_width'
					height = '$bg_height'
					fill = 'rgb(255, 255, 255)'
				/>\n";
	print FILE "	<rect
					id = 'legend_tab'
					x = '$tab_x'
					y = '$tab_y'
					width = '$tab_width'
					height = '$tab_height'
					fill = 'rgb(100, 100, 100)'
					cursor = 'pointer'
				/>\n";
	print FILE "	<text
					id = 'legend_tab_text'
					x = '$text_x'
					y = '$legend_y'
					font-family = 'Arial'
					font-size = '12'
					fill = 'rgb(255, 255, 255)'
					cursor = 'pointer'
				>
				Legend
				</text>\n";
	
	if($legend_height > $height) {
		my $button_width = $tab_height;
		my $button_height = $tab_height;
		my $button_x = $width - $button_width - 5;
		my $button_y = $height + $tab_height + $text_padding;
		#draw arrow buttons to move legend text up and down
		print FILE "	<rect 
						id = 'legend_up_btn'
						x = '$button_x'
						y = '$button_y'
						width = '$button_width'
						height = '$button_height'
						fill = 'rgb(100, 100, 100)'
						cursor = 'pointer'
						onclick = 'legend_up_btn_click(evt)'
						onmouseover = 'legend_btn_onmouseover(evt)'
						onmouseout = 'legend_btn_onmouseout(evt)'
					/>\n";
		$button_y += $button_height + $text_padding;
		print FILE "	<rect 
						id = 'legend_down_btn'
						x = '$button_x'
						y = '$button_y'
						width = '$button_width'
						height = '$button_height'
						fill = 'rgb(100, 100, 100)'
						cursor = 'pointer'
						onclick = 'legend_down_btn_click(evt)'
						onmouseover = 'legend_btn_onmouseover(evt)'
						onmouseout = 'legend_btn_onmouseout(evt)'
					/>\n";
	}
	
	print FILE "<g id = 'legend_items'>\n";
	my $ypos = $height + (2 * $text_padding);
	foreach my $edge_type (keys %edges) {
		Graph::SVG::addEdgeToLegend($edge_type, $ypos);
		$ypos += $edge_item_height;
	}
	print FILE "</g>\n";	#end legend items
	print FILE "</g>\n";	#end legend
	
	print FILE "</svg>\n";
	close FILE;
}

#--------------------------------------------------
#   Subroutine:  addEdgeToLegend
#   Description: draws edge on legend
#   Parameters:  $edge_type - name of edge type
#				              to be drawn
#		        $ypos - position in legend to draw
#			            the edge reference
#   Return:     none
#--------------------------------------------------
sub addEdgeToLegend {
	my ($edge_type, $ypos) = @_;
	my $line_pos = $ypos - 3;
	my $text_pos = $ypos + 2;
	my $xpos = 10;
	my $line_length = 100;
	my $line_end = 10 + $line_length;
	my @color = Graph::SVG::get_edgeColor ($edge_type);
	print FILE "<line
				x1 = '$xpos'
				x2 = '$line_length'
				y1 = '$line_pos'
				y2 = '$line_pos'
				stroke = 'rgb($color[0], $color[1], $color[2])'
			/>\n";
	$line_end += 5;
	print FILE "<text
				x = '$line_end'
				y = '$text_pos'
				font-family = 'Arial'
				font-size = '12'
				fill = 'rgb(0, 0, 0)'
			>
			$edge_type
			</text>\n";
}

#--------------------------------------------------
#   Subroutine:  drawNode
#   Description: draws a node on the graph
#   Parameters:  $x - x coordinate
#		         $y - y coordinate
#		         $label - text to be displayed 
#				          when the node is clicked
#		         $set - set containing node
#		         $set_num - index of set
#		         $node_num - index in containing set
#		         $filehandle - file stream to write to
#   Return:      none
#--------------------------------------------------
sub drawNode {
	my ($x, $y, $label, $set, $set_num, $node_num, $filehandle) = @_;
	
	my $fill = Graph::SVG::get_nodeFillColor ($set);
	my $alpha = 1;
	my $stroke_color = Graph::SVG::get_nodeStrokeColor ($set);
	my $stroke_width = Graph::SVG::get_nodeStrokeWidth ($set);
	my $radius = Graph::SVG::get_nodeRadius ($set);
	
	print $filehandle "<circle 
				id = '$set_num $node_num' 
				desc = '$label' 
				cx = '$x' 
				cy = '$y' 
				r = '$radius' 
				fill = '$fill' 
				stroke = '$stroke_color' 
				stroke-width = '$stroke_width'
				opacity = '$alpha' 
				cursor = 'pointer'
				onmouseover = 'node_onmouseover(evt)'
				onmouseout  = 'node_onmouseout(evt)'
				onclick = 'node_onmouseclick(evt)'
				/>", "\n";
}

1;