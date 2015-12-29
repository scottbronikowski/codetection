function top = nms_fast(boxes, overlap,K)
% Non-maximum suppression. (FAST VERSION)
% Greedily select high-scoring detections and skip detections
% that are significantly covered by a previously selected
% detection.
% NOTE: This is adapted from Pedro Felzenszwalb's version (nms.m),
% but an inner loop has been eliminated to significantly speed it
% up in the case of a large number of boxes
% Tomasz Malisiewicz (tomasz@cmu.edu)

% NOTE: Adapted from version found at
% http://www.computervisionblog.com/2011/08/blazing-fast-nmsm-from-exemplar
% -svm.html to use the [x y w h score] boxes generated by edgeBoxes or MCG

if isempty(boxes)
  top = [];
  return;
end

x1 = boxes(:,1);
y1 = boxes(:,2);
% x2 = boxes(:,3);
% y2 = boxes(:,4);
%converting from [x y w h] to [x1 y1 x2 y2]
x2 = boxes(:,3) + boxes(:,1) - 1;
y2 = boxes(:,4) + boxes(:,2) - 1;
s = boxes(:,end);

% area = (x2-x1+1) .* (y2-y1+1);
area = boxes(:,3) .* boxes(:,4);
[vals, I] = sort(s);

pick = s*0;
counter = 1;
while ~isempty(I)
  
  last = length(I);
  i = I(last);  
  pick(counter) = i;
  counter = counter + 1;
  
  xx1 = max(x1(i), x1(I(1:last-1)));
  yy1 = max(y1(i), y1(I(1:last-1)));
  xx2 = min(x2(i), x2(I(1:last-1)));
  yy2 = min(y2(i), y2(I(1:last-1)));
  
  w = max(0.0, xx2-xx1+1);
  h = max(0.0, yy2-yy1+1);
  
  o = w.*h ./ area(I(1:last-1));
  %area(I(1:last-1))
  %find(o>overlap)
  I([last; find(o>overlap)]) = [];
  %I
end

pick = pick(1:(counter-1));
if (counter-1) < K
    top = zeros(K,5);
    %boxes(pick,:)
    top(1:(counter-1),:) = boxes(pick,:);
else
    top = boxes(pick,:);
end