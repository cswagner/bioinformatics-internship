#--------------------------------------------------
# File:         methylation_visualizer.pl
# Author:       Chris Wagner
# Description:  Pulls methylation data from sorted
#               data files and graphs the relations
#               between the normal and cancerous 
#               samples.
# Date:         July 2010
#--------------------------------------------------
use Graph;

Graph::addNodeSet ([]);  #gene names
Graph::addNodeSet (["OVA1 vs. Normal"]);
#~ Graph::addNodeSet (["OVA1 vs. Normal", "OVA2 vs. Normal", "OVA3 vs. Normal"]);  #OVA1|OVA2|OVA3 vs. Normal
#~ Graph::addNodeSet (["PS1 vs. Normal", "PS2 vs. Normal", "PS3 vs. Normal"]); #PS1|PS2|PS3 vs. Normal

my $THRESHOLD = 0.05; #detailed P-Value threshold
my $EDGE_THRESHOLD = 1; #minimum number of edges on node to be included in graph

my %nodes = ();

getData ("FTNormal_OVA1_methylation_hyper.csv", "OVA1", 25); #OVA1 hypermethylation
getData ("FTNormal_OVA1_methylation_hypo.csv", "OVA1", 25); #OVA1 hypomethylation
#~ getData ("FTNormal_OVA2_methylation_hyper.csv", "OVA2", 25);  #OVA2 hypermethylation
#~ getData ("FTNormal_OVA2_methylation_hypo.csv", "OVA2", 25); #OVA2 hypomethylation
#~ getData ("FTNormal_OVA3_methylation_hyper.csv", "OVA3", 25);  #OVA3 hypermethylation
#~ getData ("FTNormal_OVA3_methylation_hypo.csv", "OVA3", 25); #OVA3 hypomethylation

#~ getData ("FTNormal_PS1_methylation_hyper.csv", "PS1", 25); #PS1 hypermethylation
#~ getData ("FTNormal_PS1_methylation_hypo.csv", "PS1", 25); #PS1 hypomethylation
#~ getData ("FTNormal_PS2_methylation_hyper.csv", "PS2", 25);  #PS2 hypermethylation
#~ getData ("FTNormal_PS2_methylation_hypo.csv", "PS2", 25); #PS2 hypomethylation
#~ getData ("FTNormal_PS3_methylation_hyper.csv", "PS3", 25);  #PS3 hypermethylation
#~ getData ("FTNormal_PS3_methylation_hypo.csv", "PS3", 25); #PS3 hypomethylation

#add edges and nodes
my $count = 0;
foreach my $key (sort (keys %nodes)) {
  #this section used for filtering nodes by the number of edges they have
  my $edge_count = 0;
  
  if ($nodes{$key} -> {'OVA1'}) {
    $edge_count++;
    #print "$key: ", $nodes{$key} -> {'OVA1'} -> {'Node_Text'}, "\n";
  }
  if ($nodes{$key} -> {'OVA2'}) {
    $edge_count++;
    #print "$key: ", $nodes{$key} -> {'OVA2'} -> {'Node_Text'}, "\n";
  }
  if ($nodes{$key} -> {'OVA3'}) {
    $edge_count++;
    #print "$key: ", $nodes{$key} -> {'OVA3'}, "\n";
  }
  
  if ($nodes{$key} -> {'PS1'}) {
    $edge_count++;
    #print "$key: ", $nodes{$key} -> {'PS1'} -> {'Type'}, "\n";
  }
  if ($nodes{$key} -> {'PS2'}) {
    $edge_count++;
  }
  if ($nodes{$key} -> {'PS3'}) {
    $edge_count++;
  }

  #~ if ($edge_count > $EDGE_THRESHOLD) {
    my $node_txt = $key;

    if ($nodes{$key} -> {'OVA1'} -> {'Type'}) {
      Graph::addEdge ([0, $count, 1, 0, $nodes{$key} -> {'OVA1'} -> {'Type'}, abs (10 * $nodes{$key} -> {'OVA1'} -> {'Difference'})]);
      $node_txt = $node_txt.$nodes{$key} -> {'OVA1'} -> {'Node_Text'};
    }
    if ($nodes{$key} -> {'OVA2'} -> {'Type'}) {
      Graph::addEdge ([0, $count, 1, 0, $nodes{$key} -> {'OVA2'} -> {'Type'}, abs (10 * $nodes{$key} -> {'OVA2'} -> {'Difference'})]);
      $node_txt = $node_txt.$nodes{$key} -> {'OVA2'} -> {'Node_Text'};
    }
    if ($nodes{$key} -> {'OVA3'} -> {'Type'}) {
      Graph::addEdge ([0, $count, 1, 0, $nodes{$key} -> {'OVA3'} -> {'Type'}, abs (10 * $nodes{$key} -> {'OVA3'} -> {'Difference'})]);
      $node_txt = $node_txt.$nodes{$key} -> {'OVA3'} -> {'Node_Text'};
    }
  
    if ($nodes{$key} -> {'PS1'} -> {'Type'}) {
      Graph::addEdge ([0, $count, 1, 0, $nodes{$key} -> {'PS1'} -> {'Type'}, abs (10 * $nodes{$key} -> {'PS1'} -> {'Difference'})]);
      $node_txt = $node_txt.$nodes{$key} -> {'PS1'} -> {'Node_Text'};
    }
    if ($nodes{$key} -> {'PS2'} -> {'Type'}) {
      Graph::addEdge ([0, $count, 1, 0, $nodes{$key} -> {'PS2'} -> {'Type'}, abs (10 * $nodes{$key} -> {'PS2'} -> {'Difference'})]);
      $node_txt = $node_txt.$nodes{$key} -> {'PS2'} -> {'Node_Text'};
    }
    if ($nodes{$key} -> {'PS3'} -> {'Type'}) {
      Graph::addEdge ([0, $count, 1, 0, $nodes{$key} -> {'PS3'} -> {'Type'}, abs (10 * $nodes{$key} -> {'PS3'} -> {'Difference'})]);
      $node_txt = $node_txt.$nodes{$key} -> {'PS3'} -> {'Node_Text'};
    }
    Graph::addNode (0, $node_txt);
    $count++;
  #~ }
}

Graph::set_nodeSize (25);
Graph::set_nodeSpace (90);
Graph::set_setSpaces (1);
Graph::toPNG ("methylation_data_OVA1_25_.png", [[255, 165, 0, 0], [0, 0, 255, 1]]);  #orange for hyper, blue for hypo

#-----subroutines-----------------------------------

#-----------------------------------------------------
# Subroutine:  getData
# Description: pulls the top 50 hyper and hypo methylated
#              genes from files and inserts the 
#              data into a hash
# Parameters:  $filename - data file path
#              $data_set - name of data set to process
#              $num_probes - number of data samples
#                            to graph
# Return:      none
#-----------------------------------------------------
sub getData {
  my ($filename, $data_set, $num_probes) = @_;
  
  #open hypermethylation data
  unless (open (FILE, $filename)) {
    print STDERR "ERROR: Cannot open $filename\n";
    exit;
  }

  #add data
  my $line_count = 0;
  my $node_count = 0;
  foreach my $line (<FILE>) {
    if($line_count > 0) {
      my @columns = split (/,/, $line);
      if ($columns[29] < $THRESHOLD) {
        if ($node_count < $num_probes) {
          if ($columns[2] eq "Decreased") {
            $nodes{"$columns[0] ($columns[1])"} -> {$data_set} -> {'Type'} = 'Hypomethylated';
	    $nodes{"$columns[0] ($columns[1])"} -> {$data_set} -> {'Difference'} = $columns[3];
	    if ($nodes{"$columns[0] ($columns[1])"} -> {$data_set} -> {'Node_Text'}) {
		$nodes{"$columns[0] ($columns[1])"} -> {$data_set} -> {'Node_Text'} = $nodes{"$columns[0] ($columns[1])"} -> {$data_set} -> {'Node_Text'}."$data_set"."_Hypo:$columns[3]";
	    }else {
		$nodes{"$columns[0] ($columns[1])"} -> {$data_set} -> {'Node_Text'} = " $data_set"."_Hypo:$columns[3]";
	    }
          }else {
            $nodes{"$columns[0] ($columns[1])"} -> {$data_set} -> {'Type'} = 'Hypermethylated';
	    $nodes{"$columns[0] ($columns[1])"} -> {$data_set} -> {'Difference'} = $columns[3];
	    if ($nodes{"$columns[0] ($columns[1])"} -> {$data_set} -> {'Node_Text'}) {
		$nodes{"$columns[0] ($columns[1])"} -> {$data_set} -> {'Node_Text'} = $nodes{"$columns[0] ($columns[1])"} -> {$data_set} -> {'Node_Text'}."$data_set"."_Hyper:$columns[3]";
	    }else {
		$nodes{"$columns[0] ($columns[1])"} -> {$data_set} -> {'Node_Text'} = " $data_set"."_Hyper:$columns[3]";
	    }
          }
          $node_count++;
        }else {
          last;
        }
      }
    }
    $line_count++;
  }

  close FILE; #hypermethylation data
}


