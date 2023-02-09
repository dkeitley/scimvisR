

// TODO: Load as an NPM package
// import { scimvis } from 'scimvis';

// export function render_scimvis(el, config, width, height, theme) {
//     // TODO: Call scimvis module functions to render widget
// }


let svg;

// set the dimensions and margins of the graph
let VIS_MARGIN , VIS_HEIGHT , VIS_WIDTH , AXES_GAP;
const opacity_low = 0.1;


function SCIMVIS_2D(el, width, height) {
  var self = this;
  var width = width;
  var height = height;
  var el= el;
  var a_data = {};
  var b_data = {};
  var mappings = {};
  var a_title = "";
  var b_title = "";
  var config = {};

  this.renderSCIMVIS = function(el, a_data, b_data, mappings, config, a_title, b_title,
          width, height) {

  	console.log("RENDERING SCIMVIS...");

  	this.a_data = a_data;
  	this.b_data = b_data;
    this.mappings = mappings;
    this.a_title = a_title;
    this.b_title = b_title;
    this.config = config;


  	VIS_MARGIN = {top: 20, right: 20, bottom: 20, left: 20};
    VIS_HEIGHT = height - VIS_MARGIN.top - VIS_MARGIN.bottom;
    VIS_WIDTH = width - VIS_MARGIN.left - VIS_MARGIN.right;
    AXES_GAP = 50;


    svg = d3.select(el)
  	  .append("svg")
    	 .attr("width",width )
  	   .attr("height",height )


  	 var a_pos = {
        xrange: [ 0, (VIS_WIDTH)/2 - AXES_GAP/2 ],
        yrange: [ VIS_HEIGHT, 0]

     }

     var b_pos = {
       xrange: [(VIS_WIDTH)/2 + AXES_GAP/2, VIS_WIDTH + AXES_GAP/2 ],
       yrange: [ VIS_HEIGHT, 0]
     }

    console.log(a_pos);
    console.log(b_pos);

    // Dipslay datasets
    var a_dataset = new Dataset(id = "a", data = a_data, name = a_title, config = this.config);
    var b_dataset = new Dataset(id = "b", data = b_data, name = b_title, this.config);

    a_dataset.show(svg, a_pos);
    b_dataset.show(svg, b_pos);

    // Make points interactive
    var link = new DatasetLink(a_dataset, b_dataset, mappings, this.config)
    link.linkDatasets(0);


  }

  this.resize = function(width, height) {

    console.log("Resizing...");
    console.log("Resized width: " + width);
    console.log("Resized height: " + height);

    this.width = width;
    this.height = height;

    // TODO: Add resizing functionality
    //self.renderSCIMVIS(this.el, this.a_data, this.b_data, this.mappings,
    //this.a_title, this.b_title, width, height)


  }

}



function Dataset (id, data, title, config) {
  var id = id;
  var name = title;
  var data = data;
  var point_ids;
  var point_elems;

  var x_axis;
  var y_axis;


  // Creates X and Y axes using D3
  this.addAxes = function(svg, pos) {

    // Add X axis
  	x_axis = d3.scaleLinear()
  	    .domain([0, 1])
  	    .range(pos.xrange);
  	svg.append("g")
  	    .attr("transform", "translate(0," + VIS_HEIGHT + ")")
  	    .call(d3.axisBottom(x_axis));

  	// Add Y axis
  	y_axis = d3.scaleLinear()
  	    .domain([0, 1])
  	    .range(pos.yrange);
  	svg.append("g")
  	    .call(d3.axisLeft(y_axis));

    return(svg)

  }


  this.addPoints = function(svg) {

    var dataset_id = this.getID();

    point_ids = data.map(function(d) { return d.id; });
    point_elems = data.map(function(d) {
      return ("#" + dataset_id + "_" + d.id);
    });


    // Add points
    svg.append('g')
      .selectAll("dot")
      .data(data)
      .enter()
      .append("circle")
      .attr("id", function (d) { return dataset_id + "_" + d.id; })
      .attr("cx", function (d) { return x_axis(Number(d.x_coord)); })
      .attr("cy", function (d) { return y_axis(Number(d.y_coord)); })
      .attr("r", config.point_size)
      .style("fill", function (d) { return d.colour; })

  }

  this.show = function(svg, pos) {

    this.addAxes(svg, pos);
    this.addPoints(svg);

  }

  this.getID = function() {
    return(id);
  }

  this.getPointIDs = function() {
    return(point_ids);
  }

  this.getData = function() {
    return(data);
  }

  this.getPoints = function() {
    return(point_elems);
  }

  this.getPointSize = function() {
    return(config.point_size);
  }

}



function DatasetLink(a_data, b_data, mapping, config) {

  var self = this;
  var datasets = [a_data, b_data];
  var focus_dataset = a_data;
  var a_data = a_data;
  var b_data = b_data;
  var mapping = mapping;
  var direction = 0;


  this.showMappings = function(hover_point, opacity, point_size, show_stroke) {

    var sim_points = mapping[hover_point.id];
    var point_ids = datasets[1-direction].getPointIDs();

		for(var i in sim_points.index) {

			var stroke_colour = "black"
			if(i == 0) stroke_colour = "gold"
			if(!show_stroke) stroke_colour = "none";

			var sim_point = sim_points.index[i];
			var sim_point_id = "#" + datasets[1-direction].getID() + "_" + point_ids[sim_point-1];

			d3.select(sim_point_id)
			.style("opacity", opacity)
			.attr("r", point_size)
			.style("stroke", stroke_colour);

		}

		// Make sure max neighbour is in front
		d3.select("#" + datasets[1-direction].getID() + "_" + point_ids[sim_points.index[0]-1])
			.raise()
			.attr('stroke-width', config.stroke_width);

  }



  this.linkDatasets = function(direction) {

    this.direction = direction;

    d3.selectAll(datasets[1-direction].getPoints().toString())
      .style("opacity", config.opacity_low);

    d3.selectAll(datasets[direction].getPoints().toString())
      .on('mouseover', function (d, i) {

        var hover_point = "#" + datasets[direction].getID() + "_" + i.id;
        d3.select(hover_point).transition()
            .duration('100')
            .attr("r", config.point_size_large);

          self.showMappings(i, 1, config.point_size_large, true);

        })
      .on('mouseout', function (d, i, group) {
        d3.select("#" + datasets[direction].getID() + "_" + i.id).transition()
            .duration('200')
            .attr("r", datasets[direction].getPointSize());
            // TODO: Reset stroke width

        self.showMappings(i, config.opacity_low, datasets[1-direction].getPointSize(), false);
    })

  }



  this.changeDirection = function() {

    this.direction = 1-direction;
    this.focus_dataset = this.datasets[this.direction];
    // TODO: Change focus

  }

}



