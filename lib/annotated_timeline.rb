module AnnotatedTimeline 

  def annotated_timeline(daily_counts_by_type, width = 750, height = 300, element = 'graph', options = {})
  
    html = "<script type=\"text/javascript\" src=\"http://www.google.com/jsapi\"></script>\n<script type=\"text/javascript\"> \n"
    html += "google.load(\"visualization\", \"1\", {packages:[\"annotatedtimeline\"]}); \n"  
    html += "google.setOnLoadCallback(drawChart);"    
    html += "function drawChart(){"  
    html += "var data = new google.visualization.DataTable(); \n"
    html += google_graph_data(daily_counts_by_type, options)
    html += "var chart = new google.visualization.AnnotatedTimeLine(document.getElementById(\'#{element}\')); \n"
    html += "chart.draw(data"   

    if options[:zoomEndTime]
        options[:zoomEndTime] = "new Date(#{options[:zoomEndTime].year}, #{options[:zoomEndTime].month-1}, #{options[:zoomEndTime].day})"
    end
    if options[:zoomStartTime]
        options[:zoomStartTime] = "new Date(#{options[:zoomStartTime].year}, #{options[:zoomStartTime].month-1}, #{options[:zoomStartTime].day})"
    end
    
    options[:colors] = "#{options[:colors].inspect}" if options[:colors]

  	options[:displayAnnotations] = true if options[:annotations]
    
    #enclose everything that google plugin expects to see as a string in javascript with escaped quotes
    options.each{|k,v| options[k] = "\"#{v}\"" if v.class==String && ![:zoomStartTime, :zoomEndTime, :colors, :scaleColumns].include?(k) }

    #set up array to get sent to options hash in javascript - which doesn't get sent the annotations hash
    array = options.delete_if{|k,v| k == :annotations}.map{|key,val| key.to_s + ": " + val.to_s}
        
    html += (", {" + array.join(", ") + "}") unless array.empty?
    html += "); } \n"		
    html += "</script>"
    html +=	"<div id=\"#{element}\" style=\"width: #{width}px\; height: #{height}px\;\"></div>"
    html

  end

  def google_graph_data(daily_counts_by_type, options)
    length = daily_counts_by_type.values.size
    column_index = {}
    num = 0
    html = ""
    
    #set up columns and assign them each an index
    html += "data.addColumn('date', 'Date'); \n"  
    daily_counts_by_type.values.inject(&:merge).stringify_keys.keys.sort.each do |type,count|
  		html+="data.addColumn('number', '#{type.to_s.titleize}');\n"
  		column_index[num+=1] = type.to_sym
  		
  		if options[:annotations]
      		if options[:annotations].keys.include?(type.to_sym)
      		    html+="data.addColumn('string', '#{type.to_s.titleize}_annotation_title');\n"
      		    column_index[num+=1] = (type.to_s + "_annotation_title").to_sym
      		    
      		    html+="data.addColumn('string', '#{type.to_s.titleize}_annotation_text');\n"
      		    column_index[num+=1] = (type.to_s + "_annotation_text").to_sym
      		    
      		    options[:annotations][type.to_sym].each do |date,array|
      		        daily_counts_by_type[date][(type.to_s + "_annotation_title").to_sym] = "\"#{array[0]}\""
      		        daily_counts_by_type[date][(type.to_s + "_annotation_text").to_sym] = "\"#{array[1]}\"" if array[1]
      		    end
    	    end
	    end
	    
  	end    
    
    html+="data.addRows(#{length});\n"
    
    html+=add_data_points(daily_counts_by_type, column_index)
    html	
  end

  def add_data_points(daily_counts_by_type, column_index)
    html = ""
    #first sort everything by date
    daily_counts_by_type.sort.each_with_index do |obj, index|
      date, type_and_count = obj
  		date_params = "#{date.year}, #{date.month-1}, #{date.day}"
  		html+="data.setValue(#{index}, 0, new Date(#{date_params}));\n"
    
      #now go through column types in the order saved in column_index
      column_index.each do |col_num, type|
        type_and_count[type] && html+="data.setValue(#{index}, #{col_num}, #{type_and_count[type]});\n"
      end
      
    end
  	html
  end

end