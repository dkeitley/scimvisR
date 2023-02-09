HTMLWidgets.widget({

  name: 'scimvis',
  type: 'output',

  factory: function(el, width, height) {

    var el = el;
    var vis = new SCIMVIS_2D(el, width, height);


    return {

      renderValue: function(x) {

        // Render widget
        var a_data = HTMLWidgets.dataframeToD3(x.a_data.data);
        var b_data = HTMLWidgets.dataframeToD3(x.b_data.data);
        var mappings = x.mappings;
        var config = x.config;

        vis.renderSCIMVIS(el, a_data, b_data, mappings, config,
        x.a_data.title, x.b_data.title, width, height);


      },

      resize: function(width, height) {

        // TODO: code to re-render the widget with a new size
       //d3.select(el).select("svg")
        //.attr("width", width)
        //.attr("height", height);

        //vis.resize(width, height);

      }

    };
  }
});





