HTMLWidgets.widget({

  name: 'scimvis',

  type: 'output',

  factory: function(el, width, height) {

    // TODO: define shared variables for this instance

    return {

      renderValue: function(x) {

        // code to render the widget

        //el.innerHTML = "test";

        var r_data = HTMLWidgets.dataframeToD3(x.r_data);
        var m_data = HTMLWidgets.dataframeToD3(x.m_data)
        //console.log(r_data);

        var sim = [];
        var nhood_ids = [];
        const x_offset = 5;
        const y_offset = 7;
        const axes_gap = 100;
        const point_size = 2.5;
        const opacity_low = 0.1;
        let r_x, r_y, m_x, m_y;


        function initScimvis(r_data, m_data) {
          var svg = createAxes();
          loadRabbitData(svg, r_data);

        }


        function createAxes() {

          // set the dimensions and margins of the graph
        	var margin = {top: 10, right: 30, bottom: 30, left: 60},
        	    width = 1200 - margin.left - margin.right,
        	    height = 600 - margin.top - margin.bottom;

          var svg = d3.select(el)
        	  .append("svg")
        	    .attr("width", width + margin.left + margin.right)
        	    .attr("height", height + margin.top + margin.bottom)
        	  .append("g")
        	    .attr("transform",
        	          "translate(" + margin.left + "," + margin.top + ")");

        	// Add X axis
        	r_x = d3.scaleLinear()
        	    .domain([-10, 20])
        	    .range([ 0, (width)/2 - 50 ]);
        	svg.append("g")
        	    .attr("transform", "translate(0," + height + ")")
        	    .call(d3.axisBottom(r_x));

        	// Add Y axis
        	r_y = d3.scaleLinear()
        	    .domain([-10, 20])
        	    .range([ height, 0]);
        	svg.append("g")
        	    .call(d3.axisLeft(r_y));

        	// Add X axis
        	m_x = d3.scaleLinear()
        	    .domain([-10, 20])
        	    .range([ (width)/2 + 50, width ]);
        	svg.append("g")
        	    .attr("transform", "translate(0," + height + ")")
        	    .call(d3.axisBottom(m_x));

        	// Add Y axis
        	m_y = d3.scaleLinear()
        	    .domain([-10, 20])
        	    .range([ height, 0]);
        	svg.append("g")
        	    .call(d3.axisLeft(m_y));

        	return(svg);
        }




        function loadRabbitData(svg, data) {

          nhood_ids[0] = data.map(function(d) { return d.nhood; });

          // Add dots
          svg.append('g')
            .selectAll("dot")
            .data(data)
            .enter()
            .append("circle")
              .attr("id", function (d) { return "r_" + d.nhood; } )
              .attr("cx", function (d) { return r_x(Number(d.umapX)); } )
              .attr("cy", function (d) { return r_y(Number(d.umapY)); } )
              .attr("r", point_size)
              .style("fill", function (d) { return d.colour; } )
              /*
              .on('mouseover', function (d, i) {
               d3.select(this).transition()
                    .duration('100')
                    .attr("r", 7);

               toggleNeighbours(i, 1, true);

                })
              .on('mouseout', function (d, i) {
               d3.select(this).transition()
                    .duration('200')
                    .attr("r", point_size);

               toggleNeighbours(i, opacity_low, false);
          	})
          	*/

        }



        function loadMouseData(svg, data) {

          nhood_ids[1] = data.map(function(d) { return d.nhood; });

        	// Add dots
        	svg.append('g')
        		    .selectAll("dot")
        		    .data(m_data)
        		    .enter()
        		    .append("circle")
        		      .attr("id", function (d) { return "m_" + d.nhood; } )
        		      .attr("cx", function (d) { return m_x(Number(d.umapX) + x_offset) ; } )
        		      .attr("cy", function (d) { return m_y(Number(d.umapY) + y_offset); } )
        		      .attr("r", point_size)
        		      .style("fill", function (d) { return d.colour; } )
        		      .style("opacity", opacity_low)

        }


        initScimvis(r_data, m_data)



      },

      resize: function(width, height) {

        // TODO: code to re-render the widget with a new size

      }

    };
  }
});





