HTMLWidgets.widget({

  name: 'scimvis',

  type: 'output',

  factory: function(el, width, height) {

    return {

      renderValue: function(x) {

        // code to render the widget

        //el.innerHTML = "test";

        var r_data = HTMLWidgets.dataframeToD3(x.r_data);
        var m_data = HTMLWidgets.dataframeToD3(x.m_data);

        //render_scimvis(el, data);

        initScimvis(el, r_data, m_data)



      },

      resize: function(width, height) {

        // TODO: code to re-render the widget with a new size

      }

    };
  }
});





