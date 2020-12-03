function [error_segment_start, error_segment_end] = findLargestErrorSegment(filter_curve1, filter_curve2)

% find intersection lines
intersections = findIntersections(filter_curve1, filter_curve2);

% define number of segments
numSegments = length(intersections) + 1;
error_list = zeros(numSegments, 1);

%append start & end for first & last segment
intersections = [1; intersections; size(filter_curve1, 2)]; 


%walk over every segment and determine error
for i = 1:numSegments
    
    error_segment_start = intersections(i);
    error_segment_end = intersections(i+1);
    
    segment1 = filter_curve1(error_segment_start:error_segment_end);
    segment2 = filter_curve2(error_segment_start:error_segment_end);
    
    %make pseudo-area between curves to compare them
    error_list(i) = sum(abs(segment1 - segment2));
   
end

[maxval, id] = max(error_list);

error_segment_start = intersections(id);
error_segment_end = intersections(id+1);



