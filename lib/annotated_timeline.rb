
## Sample generated Javascript

# <script type="text/javascript" src="http://www.google.com/jsapi"></script>
# <script type="text/javascript"> 
# google.load("visualization", "1", {packages:["annotatedtimeline"]}); 
# google.setOnLoadCallback(drawChart);function drawChart(){var data = new google.visualization.DataTable(); 
# data.addColumn('date', 'Date'); 
# data.addColumn('number', 'All');
# data.addColumn('number', 'Invalid');
# data.addColumn('number', 'Opt Out');
# data.addRows(166);
# data.setValue(0, 0, new Date(2008, 6, 6));
# data.setValue(0, 1, 216);
# data.setValue(0, 2, 27);
# data.setValue(0, 3, 10);
# data.setValue(1, 0, new Date(2008, 6, 7));
# data.setValue(1, 1, 327);
# data.setValue(1, 2, 45);
# data.setValue(1, 3, 14);



module AnnotatedTimeline 

    #this version will automatically create a div inline for you. 
    #note that if it is in the middle of the page, the javascript will try to execute before the page load completes
  def inline_annotated_timeline(daily_counts_by_type, width = 750, height = 300, div_id_to_create = 'graph', options = {})
    html = "<script type=\"text/javascript\" src=\"http://www.google.com/jsapi\"></script>"
    html += annotated_timeline(daily_counts_by_type, div_id_to_create, options)
    html + "<div id=\"#{div_id_to_create}\" style=\"width: #{width}px\; height: #{height}px\;\"></div>"    
  end

  #you must create a div on your page and pass in the div id
  def annotated_timeline(daily_counts_by_type, div_id = 'graph', options = {})

    google_graph_html = google_graph_data(daily_counts_by_type, options)

    google_options = format_options_for_javascript(options)
    data_args = google_options.any? ? "data, {#{google_options.join(", ")}}" : "data"
    
    html = "<script type=\"text/javascript\">
    google.load(\"visualization\", \"1\", {packages:[\"annotatedtimeline\"]});
    google.setOnLoadCallback(drawChart);
    function drawChart(){
      var data = new google.visualization.DataTable();
      #{google_graph_html}
      var chart = new google.visualization.AnnotatedTimeLine(document.getElementById(\'#{div_id}\'));
      chart.draw(#{data_args}); 
    }
    </script>"
  end

private

  def ruby_time_to_js_time(time)
    "new Date(#{time.year}, #{time.month-1}, #{time.day})"
  end

  def ruby_hash_to_js_hash(hash)
    hash.map{|key,val| "#{key}: #{val}"}
  end
  
  def format_options_for_javascript(options)
   valid_options = {}
   options.each do |k,v|
     valid_options[k] = case v
       when String, Array    then v.inspect   #this turns 'red' into '\"red\"' for strings and %w[red blue] into [\"red\", \"blue\"] for arrays 
       when Date,Time        then ruby_time_to_js_time(v) 
       else v       #leave bools and numbers as they are         
      end
   end 
    
    # a hash containing annotations is passed into the ruby options hash, keyed as :annotations. this hash
    # doesn't get sent to the javascript function - javascript takes the annotations as data points. the js
    # function does, however, require the boolean :displayAnnotations
    if (options[:annotations] && options[:annotations].any?)
      valid_options[:displayAnnotations] = true
    end
    valid_options.reject!{|k,v| k == :annotations || v == nil}
    
    ruby_hash_to_js_hash valid_options 
  end
  
  def google_graph_data(daily_counts_by_type, options)
    categories = []
    num = 0
    html = ""
    
    #set up columns and assign them each an index
    html += "data.addColumn('date', 'Date'); \n"  
    types( daily_counts_by_type ).each do |type|
  		html+="data.addColumn('number', '#{type.titleize}');\n"
  		categories << type.to_sym
  		
  		if options[:annotations] && options[:annotations].keys.include?(type.to_sym)
  		  html+="data.addColumn('string', '#{type.titleize}_annotation_title');\n"
		    categories << "#{type}_annotation_title".to_sym
		    
		    html+="data.addColumn('string', '#{type.titleize}_annotation_text');\n"
		    categories << "#{type}_annotation_text".to_sym
		    
		    options[:annotations][type.to_sym].each do |date, array|
	        daily_counts_by_type[date]["#{type}_annotation_title".to_sym] = "\"#{array[0]}\""
	        daily_counts_by_type[date]["#{type}_annotation_text".to_sym] = "\"#{array[1]}\"" if array[1]
		    end
	    end    
  	end    
    
    #The script expects a constant telling it how many rows we're going to add
    html+="data.addRows(#{daily_counts_by_type.size});\n"
    
    html+=add_data_points(daily_counts_by_type, categories)
    html	
  end

  # Converts this:
  # { :Date1=>{:type1=>9, :type2=>9},
  #   :Date2=>{:type1=>9, :type3=>9} }
  # into
  #  ['type1', 'type2', 'type3']
  # We can't just take the keys of the first item because not every date has every category
  def types( daily_counts_by_type )
    daily_counts_by_type.values.inject(&:merge).stringify_keys.keys.sort
  end
  
  def add_data_points(daily_counts_by_type, categories)
    html = ""
    #sort by date
    daily_counts_by_type.sort.each_with_index do |obj, index|
      date, type_and_count = obj
      html+="data.setValue(#{index}, 0, #{ruby_time_to_js_time(date)});\n"
    
      #now, on a particular date, go through columns 
      categories.each_with_index do |category, idx2|
        if type_and_count[category] 
          html+="data.setValue(#{index}, #{idx2+1}, #{type_and_count[category]});\n"
        end
      end      
    end
  	html
  end

end