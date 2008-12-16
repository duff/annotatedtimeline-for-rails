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


    if options[:zoomEndDate]
        options[:zoomEndDate] = "new Date(#{options[:zoomEndDate].year}, #{options[:zoomEndDate].month-1}, #{options[:zoomEndDate].day})"
    end
    
    if options[:zoomStartDate]
        options[:zoomStartDate] = "new Date(#{options[:zoomStartDate].year}, #{options[:zoomStartDate].month-1}, #{options[:zoomStartDate].day})"
    end
    
    if options[:colors]
        options[:colors] = "#{options[:colors].inspect}"
    end
  	
  	if options[:annotations]
  	    options[:displayAnnotations] = true
    end
  	

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
      		    options[:annotations][type.to_sym].each do |date,txt|
      		        daily_counts_by_type[date][(type.to_s + "_annotation_title").to_sym] = "\"#{txt}\""
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