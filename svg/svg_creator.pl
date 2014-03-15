use Graph;
use Graph::SVG;

Graph::addNodeSet("node1", [1,2,3,4,5,1,2,3,4,5,1,2,3,4,5,1,2,3,4,5,1,2,3,4,5,1,2,3,4,5,1,2,3,4,5]);
Graph::addNodeSet("node2", [6,7,8,9,0]);
Graph::addEdges([0, 0, 1, 0, 'hyper', 1], 
			[0, 0, 1, 4, 'hypo', 2.34574932], 
			[0, 1, 1, 0, 'super', 1], 
			[0, 0, 1, 3, 'hyper', 3],
			[0, 15, 1, 3, 'super', 2],
			[0, 8, 1, 0, 'hyper', 1],
			[0, 11, 1, 1, 'super', 1],
			[0, 18, 1, 3, 'hypo', 1],
			[0, 5, 1, 0, 'hypo', 1],
			[0, 20, 1, 4, 'hypo', 4]);

Graph::SVG::toSVG ("ex_2.svg", "nodes.style");

