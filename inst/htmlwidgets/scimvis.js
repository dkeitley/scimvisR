HTMLWidgets.widget({

  name: 'scimvis',

  type: 'output',

  factory: function(el, width, height) {

    return {

      renderValue: function(x) {

        // code to render the widget

        //el.innerHTML = "test";

        var a_data = HTMLWidgets.dataframeToD3(x.a_data.data);
        var b_data = HTMLWidgets.dataframeToD3(x.b_data.data);
        var mappings = x.mappings;

        renderSCIMVIS(el, a_data, b_data, mappings,
        x.a_data.title, x.b_data.title);


      },

      resize: function(width, height) {

        // TODO: code to re-render the widget with a new size

      }

    };
  }
});





