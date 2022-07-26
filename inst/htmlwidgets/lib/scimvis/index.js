// TODO: Load as an NPM package
// import { scimvis } from 'scimvis';

// export function render_scimvis(el, config, width, height, theme) {
//     // TODO: Call scimvis module functions to render widget
// }


let svg;

// set the dimensions and margins of the graph
var margin = {top: 10, right: 30, bottom: 30, left: 60},
	    width = 1200 - margin.left - margin.right,
	    height = 600 - margin.top - margin.bottom;


const axes_gap = 100;
const point_size = 2.5;
const opacity_low = 0.1;



function renderSCIMVIS(el, a_data, b_data, mappings, a_title, b_title) {

	console.log("RENDERING SCIMVIS...");

  svg = d3.select(el)
	  .append("svg")
	    .attr("width", width + margin.left + margin.right)
	    .attr("height", height + margin.top + margin.bottom)
	  .append("g")
	    .attr("transform",
	          "translate(" + margin.left + "," + margin.top + ")");

	 var a_pos = {
      xrange: [ 0, (width)/2 - axes_gap/2 ],
      yrange: [ height, 0]

   }

   var b_pos = {
     xrange: [ (width)/2 + axes_gap/2, width ],
     yrange: [ height, 0]
   }


  // Dipslay datasets
  var a_dataset = new Dataset(id = "a", data = a_data, name = a_title);
  var b_dataset = new Dataset(id = "b", data = b_data, name = b_title);

  a_dataset.show(svg, a_pos);
  b_dataset.show(svg, b_pos);

  // Make points interactive
  var link = new DatasetLink(a_dataset, b_dataset, mappings)
  link.linkDatasets(0);


}



function Dataset (id, data, title) {
  var id = id;
  var name = title;
  var data = data;
  var point_ids;
  var point_elems;

  var x_axis;
  var y_axis;

  // Dataset settings (e.g. point size)
  var config = {
    point_size: 2.5
  }

  // Creates X and Y axes using D3
  this.addAxes = function(svg, pos) {

    // Add X axis
  	x_axis = d3.scaleLinear()
  	    .domain([0, 1])
  	    .range(pos.xrange);
  	svg.append("g")
  	    .attr("transform", "translate(0," + height + ")")
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







function DatasetLink(a_data, b_data, mapping) {

  var self = this;
  var datasets = [a_data, b_data];
  var focus_dataset = a_data;
  var a_data = a_data;
  var b_data = b_data;
  var mapping = mapping;
  var direction = 0;

  var config = {
    opacity_low: 0.1,
    point_size_large: 7,
    stroke_width: '2'
  }

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

        self.showMappings(i, config.opacity_low, datasets[1-direction].getPointSize(), false);
    })

  }



  this.changeDirection = function() {

    this.direction = 1-direction;
    this.focus_dataset = this.datasets[this.direction];
    // TODO: Change focus

  }

}





//var sim = [];
//var nhood_ids = {};







