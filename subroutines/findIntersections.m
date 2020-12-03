function [intersections] = findIntersections(vector1,vector2)

if length(vector1) ~= length(vector2)
    error("Vector 1&2 are not of same length");
end

%make delta vector and then compute zero crossings
dV = vector1 - vector2;

intersections = find((dV(:).*circshift(dV(:), [-1 0]) <= 0));


end

