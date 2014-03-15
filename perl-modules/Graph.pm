#--------------------------------------------------
#   File:        Graph.pm
#   Author:      Chris Wagner
#   Description: provides methods for graphing 
#                a set of sets with a set of edges
#                of varying types
#   Date:        7/9/10
#--------------------------------------------------
package Graph;

use GD;
use GD::Polyline;

srand (time ^ ($$ + ($$ << 15)));

my @nodes = ();     #set of node sets ([node, node, node, ...], [node, node, ...], ...)
my @set_names = ();	#names of the node sets
my @edges = ();     #set of 6-tuples representing edges [set_1, element_in_1, set_2, element_in_2, edge_type, weight (optional)]

#PNG graph constants
my $SET_SPACE = 1;
my $NODE_SIZE = 10;
my $DELTA_POS = 20;

#--------------------------------------------------
#   Subroutine:  addNodeSet
#   Description: adds a set of nodes to @nodes
#   Parameters:  $set - [...] of nodes
#   Return:      none
#--------------------------------------------------
sub addNodeSet {
  my ($name, $set) = @_;
  push @set_names, $name;
  push @nodes, $set;
}

#--------------------------------------------------
#   Subroutine:  removeNodeSet
#   Description: removes a set of nodes from @nodes
#   Parameters:  $set - index of set to be removed
#   Return:      none
#--------------------------------------------------
sub removeNodeSet {
  my ($set) = @_;
  splice (@set_names, $set, 1);
  splice (@nodes, $set, 1);
}

#--------------------------------------------------
#   Subroutine:  addNode
#   Description: adds a node to a node set in @nodes
#   Parameters:  $set - node set index in @nodes
#                $node - value of node to be added
#   Return:      none
#--------------------------------------------------
sub addNode {
  my ($set, $node) = @_;
  my $node_set = $nodes[$set];
  push @$node_set, $node;
}

#--------------------------------------------------
#   Subroutine:  addNodes
#   Description: adds a list of nodes to a node set
#                in @nodes
#   Parameters:  $set - node set index in @nodes
#                $node_list - list of nodes to be added
#   Return:      none
#--------------------------------------------------
sub addNodes {
  my ($set, $node_list) = @_;
  my $node_set = $nodes[$set];
  foreach my $node (@$node_list) {
    push @$node_set, $node;
  }
}

#--------------------------------------------------
#   Subroutine:  addEdge
#   Description: adds an edge to @edges
#   Parameters:  $edge - edge 6-tuple to be added
#   Return:      none
#--------------------------------------------------
sub addEdge {
  my ($edge) = @_;
  push @edges, $edge;
}

#--------------------------------------------------
#   Subroutine:  removeEdge
#   Description: removes an edge from @edges
#   Parameters:  $edge - index of edge to be 
#                        removed
#   Return:      none
#--------------------------------------------------
sub removeEdge {
  my ($edge) = @_;
  splice (@edges, $edge, 1);
}

#--------------------------------------------------
#   Subroutine:  addEdges
#   Description: adds a list of edges to @edges
#   Parameters:  @edge_list - list of edge 6-tuples 
#                             to be added
#   Return:      none
#--------------------------------------------------
sub addEdges {
  my (@edge_list) = @_;
  foreach my $edge (@edge_list) {
    push @edges, $edge;
  }
}

#--------------------------------------------------
#   Subroutine:  get_edgeStart
#   Description: returns set and element of edge
#                starting node
#   Parameters:  $edge - index of edge in @edges
#   Return:      set containing node, node index in set
#                OR -1, -1 if out of range
#--------------------------------------------------
sub get_edgeStart {
  my ($edge) = @_;
  if ($edge > (scalar @edges - 1) || $edge < 0) {
    print STDERR "ERROR: edge does not exist.\n";
    return -1, -1; 
  }else {
    return $edges[$edge][0], $edges[$edge][1];
  }
}

#--------------------------------------------------
#   Subroutine:  get_edgeEnd
#   Description: returns set and element of edge
#                ending node
#   Parameters:  $edge - index of edge in @edges
#   Return:      set containing node, node index in set
#                OR -1, -1 if out of range
#--------------------------------------------------
sub get_edgeEnd {
  my ($edge) = @_;
  if ($edge > (scalar @edges - 1) || $edge < 0) { 
    print STDERR "ERROR: edge does not exist.\n";
    return -1, -1; 
  }else {
    return $edges[$edge][2], $edges[$edge][3];
  }
}

#--------------------------------------------------
#   Subroutine:  get_edgeType
#   Description: returns edge type
#   Parameters:  $edge - index of edge in @edges
#   Return:      edge type string OR nothing if
#                out of range
#--------------------------------------------------
sub get_edgeType {
  my ($edge) = @_;
  if ($edge > (scalar @edges - 1) || $edge < 0) {
    print STDERR "ERROR: edge does not exist.\n";
    return; 
  }else {
    return $edges[$edge][4];
  }
}

#--------------------------------------------------
#   Subroutine:  get_edgeWeight
#   Description: returns edge weight
#   Parameters:  $edge - index of edge in @edges
#   Return:      edge weight number OR nothing
#                if out of range
#--------------------------------------------------
sub get_edgeWeight {
  my ($edge) = @_;
  if ($edge > (scalar @edges - 1) || $edge < 0) {
    print STDERR "ERROR: edge does not exist.\n";
    return; 
  }else {
    return $edges[$edge][5];
  }
}

#--------------------------------------------------
#   Subroutine:  nodesToString
#   Description: prints each set of nodes on a line
#   Parameters:  none
#   Return:      none
#--------------------------------------------------
sub nodesToString {
  my $count = 0;
  foreach my $node_list (@nodes) {
    foreach my $node (@$node_list) {
      print "$node\n";
      $count++;
    }
    print "\n";
  }
  print "Number of Nodes: $count\n";
}

#--------------------------------------------------
#   Subroutine:  edgesToString
#   Description: prints each edge in @edges on a line
#   Parameters:  none
#   Return:      none
#--------------------------------------------------
sub edgesToString {
  foreach my $edge (@edges) {
    foreach my $edge_prop (@$edge) {
      print "$edge_prop ";
    }
    print "\n";
  }
}

#--------------------------------------------------
#   Subroutine:  toPNG
#   Description: writes the graph to a PNG file
#                     using the GD module
#   Parameters:  $png_filename - PNG output file
#                $color_table - [[r, g, b], [r, g, b], ...]
#                               table of colors to be used as the 
#                               edge colors
#   Return:      none
#--------------------------------------------------
sub toPNG {
  my ($png_filename, $color_table) = @_;
  
  #ability to predefine edge colors
  my @color_array = @$color_table;
  my $color_ptr = 0;
  
  #setup PNG image
  my $r = 1;
  my $g = 1;
  my $b = 1;
  
  my $num_nodes = 0;
  foreach my $node_list (@nodes) {
    $num_nodes += scalar @$node_list;
  }
  $num_nodes += (scalar @nodes * $SET_SPACE);
  
  if ($num_nodes <= 0) {
    print STDERR "ERROR: No data given\n";
    exit;
  }
  
  #get number of edge types and add them to the edge key
  #***NOTE: edges are made styled on all even numbered sets of edge types
  my %edge_hash = ();
  my $edge_num = 1;
  my $KEY_HEIGHT = $DELTA_POS;
  foreach my $e (@edges) {
    if (not exists $edge_hash{@$e[4]}) {
      if ($color_table) {
        $r = $color_array[$color_ptr][0];
        $g = $color_array[$color_ptr][1];
        $b = $color_array[$color_ptr][2];
	$edge_hash{@$e[4]} -> {'styled'} = $color_array[$color_ptr][3];
        $color_ptr++;
      }else {
        $r = int (rand (200) + 55);
        $g = int (rand (200) + 55);
        $b = int (rand (200) + 55);
	if ($edge_num % 2 == 0) {
	  $edge_hash{@$e[4]} -> {'styled'} = 1;
        }else {
          $edge_hash{@$e[4]} -> {'styled'} = 0;
        }
      }
      $edge_hash{@$e[4]} -> {'red'} = $r;
      $edge_hash{@$e[4]} -> {'green'} = $g;
      $edge_hash{@$e[4]} -> {'blue'} = $b;
      $edge_num++;
    }
  }
  undef $edge_num;
  $KEY_HEIGHT += (scalar (keys %edge_hash)) * 30;
  
  #-----
  my $diam_x = ($num_nodes/2) * $DELTA_POS;
  my $diam_y = ($num_nodes/2) * $DELTA_POS;
  my $WIDTH = $diam_x + (2 * ($DELTA_POS + 100));
  my $HEIGHT = $diam_y + (2 * $DELTA_POS) + $KEY_HEIGHT + 200;
  my $ANGLE_SLICE = 6.28/$num_nodes;
  my $img = new GD::Image ($WIDTH, $HEIGHT, 1) || die;
  
  $white = $img -> colorAllocate (255, 255, 255);
  $lightgray = $img -> colorAllocate (180, 180, 180);
  $black = $img -> colorAllocate (0, 0, 0);
  $img -> setAntiAliased($black);
  
  $img -> filledRectangle (0, 0, $WIDTH - 1, $HEIGHT - 1, $white);
  $img -> transparent ($white);
  $img -> interlaced ('true');
  #-----end setup-----
  
  #draw edge legend
  #$img -> filledRectangle (0, $WIDTH, $WIDTH - 1, $WIDTH + $KEY_HEIGHT - 1, $lightgray);
  if(scalar (keys %edge_hash) > 0) {
    $img -> rectangle (0, $WIDTH + $DELTA_POS, $WIDTH - 1, $WIDTH + $KEY_HEIGHT - 1, $black);

    my $legend_pos = $WIDTH + $DELTA_POS + 10;
    foreach my $key (keys %edge_hash) {
      my $style;
      my $edge_color;
    
      $edge_color = $img -> colorAllocate ($edge_hash{$key} -> {'red'}, $edge_hash{$key} -> {'green'}, $edge_hash{$key} -> {'blue'});
      if ($edge_hash{$key} -> {'styled'} == 1) {
        my @style = ($edge_color, $edge_color, $edge_color, GD::gdTransparent, GD::gdTransparent, GD::gdTransparent, GD::gdTransparent, GD::gdTransparent);
        $img -> setStyle (@style);
        $style = GD::gdStyled;
      }else {
        $style = $edge_color;
      }
    
      $img -> setAntiAliased ($style);
      $img -> line (10, $legend_pos, $WIDTH/5, $legend_pos, $style);
      $img -> string (GD::gdGiantFont, ($WIDTH/5) + 10, $legend_pos - 6, $key, $black);
      $legend_pos += 30;
    }
  }
  #-----
  
  #TO DO: draw edges
  my $node_pos = 0;
  my $edge_count = 0;
  my $angle;

  foreach my $edge (@edges) {
    #find start node
    $angle = $ANGLE_SLICE;
    $node_pos = 0;
    my ($set, $index) = Graph::get_edgeStart($edge_count);
    
    for (my $i = 0; $i < $set; ++$i) {
      my $list_ref = $nodes[$i];
      my @list = @$list_ref;
      $node_pos += scalar @list + $SET_SPACE;
    }
    $node_pos += $index;
    $angle += $ANGLE_SLICE * $node_pos;
    
    my $n1_x = ($WIDTH/2) - (($diam_x/2) * cos ($angle));
    my $n1_y = ($WIDTH/2) + (($diam_y/2) * sin ($angle));
    
    #find end node
    $node_pos = 0;
    $angle = $ANGLE_SLICE;
    my ($set, $index) = Graph::get_edgeEnd($edge_count);
    
    for (my $i = 0; $i < $set; ++$i) {
      my $list_ref = $nodes[$i];
      my @list = @$list_ref;
      $node_pos += scalar @list + $SET_SPACE;
    }
    $node_pos += $index;
    $angle += $ANGLE_SLICE * $node_pos;
    
    my $n2_x = ($WIDTH/2) - (($diam_x/2) * cos ($angle));
    my $n2_y = ($WIDTH/2) + (($diam_y/2) * sin ($angle));
    
    #draw edge
    
    #edge weight
    if (Graph::get_edgeWeight($edge_count) > 0) {
      $img -> setThickness (Graph::get_edgeWeight($edge_count));
    
      #style based on edge type
      my $style;
      my $edge_color;
    
      $edge_color = $img -> colorAllocate ($edge_hash{Graph::get_edgeType($edge_count)} -> {'red'}, $edge_hash{Graph::get_edgeType($edge_count)} -> {'green'}, $edge_hash{Graph::get_edgeType($edge_count)} -> {'blue'});
      if ($edge_hash{Graph::get_edgeType($edge_count)} -> {'styled'} == 1) {
        my @style = ($edge_color, $edge_color, $edge_color, GD::gdTransparent, GD::gdTransparent, GD::gdTransparent, GD::gdTransparent, GD::gdTransparent, GD::gdTransparent, GD::gdTransparent, GD::gdTransparent, GD::gdTransparent, GD::gdTransparent, GD::gdTransparent, GD::gdTransparent, GD::gdTransparent, GD::gdTransparent, GD::gdTransparent);
        $img -> setStyle (@style);
        $style = GD::gdStyled;
      }else {
        $style = $edge_color;
      }
    
      $img -> setAntiAliased ($style);
    
      #$img -> line ($n1_x + ($NODE_SIZE/2), $n1_y + ($NODE_SIZE/2), $n2_x + ($NODE_SIZE/2), $n2_y + ($NODE_SIZE/2), $black);
      my $arc = new GD::Polyline;
    
      $arc -> addPt ($n1_x + ($NODE_SIZE/2),  $n1_y + ($NODE_SIZE/2));
      $arc -> addPt ((($WIDTH/2) + (($n1_x + $n2_x + $NODE_SIZE)/2))/2,  (($WIDTH/2) + (($n1_y + $n2_y + $NODE_SIZE)/2))/2);
      $arc -> addPt ($n2_x + ($NODE_SIZE/2), $n2_y + ($NODE_SIZE/2));
      my $spline = $arc->addControlPoints->toSpline;
      $img -> polydraw ($spline, $style);
    }
    
    $img -> colorDeallocate ($edge_hash{Graph::get_edgeType($edge_count)} -> {'red'}, $edge_hash{Graph::get_edgeType($edge_count)} -> {'green'}, $edge_hash{Graph::get_edgeType($edge_count)} -> {'blue'});
    
    #reset line weight for later drawing
    $img -> setThickness (1);
    $edge_count++;
  }
  
  my $node_num = 0;
  my $pos_x = ($WIDTH/2) - ($diam_x/2);
  my $pos_y = ($WIDTH/2);
  $angle = $ANGLE_SLICE;
  my $node_color = $black;
  
  #draw nodes
  foreach my $node_list (@nodes) {
    #NEEDS WORK: change set color
    #~ $r = int (rand (200) + 55);
    #~ $g = int (rand (200) + 55);
    #~ $b = int (rand (200) + 55);
    #~ $node_color = $img -> colorAllocate ($r, $g, $b);
    
    foreach my $node (@$node_list) {
      #move to next position
      $pos_x = ($WIDTH/2) - (($diam_x/2) * cos ($angle));
      $pos_y = ($WIDTH/2) + (($diam_y/2) * sin ($angle));
      $string_x = ($WIDTH/2) - ((($diam_x/2) + ($NODE_SIZE)) * cos ($angle));
      $string_y = ($WIDTH/2) + ((($diam_y/2) + ($NODE_SIZE)) * sin ($angle));
      $angle += $ANGLE_SLICE;
      
      #$img -> setThickness ($NODE_SIZE/2);
      #$img -> arc ($pos_x + ($NODE_SIZE/2), $pos_y + ($NODE_SIZE/2), ($NODE_SIZE/4), ($NODE_SIZE/4), 0, 360, $black);
      #$img -> setThickness (1);
      #$img -> fillToBorder ($pos_x + ($NODE_SIZE/2), $pos_y + ($NODE_SIZE/2), $node_color, $node_color);
      $img -> arc ($pos_x + ($NODE_SIZE/2), $pos_y + ($NODE_SIZE/2), $NODE_SIZE, $NODE_SIZE, 0, 360, $lightgray);
      
      my @node_txt = split (/\s/, $node);
      foreach my $str (@node_txt) {
        $img -> string (GD::gdSmallFont, $string_x, $string_y, $str, $black);
        $string_y += 15;
      }
      
      $node_num++;
    }
    $angle += ($ANGLE_SLICE * $SET_SPACE);
  }
  
  #write PNG to file
  $img -> rectangle (0, 0, $WIDTH - 1, $HEIGHT - 1, $black);
  
  unless (open (PNG_FILE, ">$png_filename")) {
    print STDERR "ERROR: cannot open $png_filename.\n";
    exit;
  }
  
  binmode PNG_FILE;
  print PNG_FILE $img->png(9) || die "CANNOT WRITE PNG\n";
  
  close PNG_FILE;
}

#--------------------------------------------------
#   Subroutine:  set_setSpaces
#   Description: modifies the number of node spaces
#                between subsequent sets
#   Parameters:  number of spaces
#   Return:      none
#--------------------------------------------------
sub set_setSpaces {
  ($SET_SPACE) = @_;
}

sub get_setSpaces {
	return $SET_SPACE;
}

#--------------------------------------------------
#   Subroutine:  set_nodeSize
#   Description: modifies the size of a node
#   Parameters:  node diameter number
#   Return:      none
#--------------------------------------------------
sub set_nodeSize {
  ($NODE_SIZE) = @_;
}

#--------------------------------------------------
#   Subroutine:  set_nodeSpace
#   Description: modifies the space between nodes
#   Parameters:  space between nodes number
#   Return:      none
#--------------------------------------------------
sub set_nodeSpace {
  ($DELTA_POS) = @_;
}

sub get_nodeSpace {
	return $DELTA_POS;
}

#--------------------------------------------------
#   Subroutine:  get_numSets
#   Description: returns the number of sets
#   Parameters:  none
#   Return:      number of sets
#--------------------------------------------------
sub get_numSets {
  return scalar @nodes;
}

#--------------------------------------------------
#   Subroutine:  get_numEdges
#   Description: returns the number of edges
#   Parameters:  none
#   Return:      number of edges
#--------------------------------------------------
sub get_numEdges {
  return scalar @edges;
}

sub get_Nodes {
	return \@nodes;
}

sub get_setNames {
	return \@set_names;
}

sub get_Edges {
	return \@edges;
}

1;








