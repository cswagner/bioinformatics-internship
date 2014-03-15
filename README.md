# Bioinformatics Internship

During the summer of 2010 I worked as a research intern in the [Bioinformatics Laboratory](http://www.ohio.edu/bioinformatics/ "Ohio University Bioinformatics") at [Ohio University](http://www.ohio.edu/ "Ohio University Homepage") in [Athens, OH](https://www.google.com/maps/place/Athens,+OH+45701/@39.3344156,-82.1026,14z/data=!4m2!3m1!1s0x88487a8a2843c5d3:0x30b0012f06624a2b?hl=en "Map of Athens, OH"). 

My work was on the visualization of relationships between methylation levels in cancerous ovarian cells and normal ovarian cells.  This repo serves as a summary of my contributions and collaborations during that time:

### perl-modules
---

##### Graph.pm
 
A Perl module used to show relationships between n nodes in k sets with a set of edges of varying types; output as a PNG image.
    
##### Graph/SVG.pm
 
A Perl module that expands on the capabilities of the Graph module above, but outputs as an interactive Scalable Vector Graphic (SVG).

##### Graph/svg_default.style

The Graph/SVG module allows node sets and edge sets to be defined by an external style sheet. svg_default.style defines the default style when no other file is provided. 

*To define the properties of a set of nodes:*
```
set:
	name:              default
	node-fill:         rgb(255, 0, 0)
	node-alpha:        0.1
	node-stroke-color: rgb(0, 0, 0)
	node-stroke-width: 1
	node-radius:       10
```	
*To define the properties of a set of edges:*
```
edge:
	name:   default
	color:  rgb(0, 0, 0)
	dashed: false
```

### methylation
---

##### methylation_visualizer.pl

A Perl script that uses perl-modules/Graph to generate PNG images visualizing the relationships between cancerous and normal ovarian cells. The input data has been redacted as it is not mine to distribute, but a few sample result images have been included in methylation/results.

*Ex.*
<p align="center">
  <img src="https://raw.github.com/cswagner/bioinformatics-internship/master/methylation/results/top-10/methylation_data_minedge_filter_all_10_.png" alt="Sample Methylation Output" width=640 height=715/>
</p>

### motifs
---

##### motifs.pl

A Perl script that uses perl-modules/Graph to visualize DNA word clusters (motifs) identified in *[Regulatory Network Nodes of Check Point Factors in DNA Repair Pathways](http://dl.acm.org/citation.cfm?id=1854877 "Publication Link")*.

##### motifs.png

The resulting visualization:
<p align="center">
  <img src="https://raw.github.com/cswagner/bioinformatics-internship/master/motifs/motifs.png" alt="Motifs Visualization" width=710 height=1180/>
</p>
