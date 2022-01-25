function circlesArrayFlat = eightCirclesArray(gr_highRes, radMin, radMax)

  #tries to find 8 circles, lowering param2  
  for p = 35:-1:10
    tic;
    circles = cv.HoughCircles(gr_highRes, 
                            'MinRadius', radMin,
                            'MaxRadius', radMax,
                            #'Param1', param1, 
                            'Param2', p,
                            'MinDist', 1000
                            #'DP', 1
                       );  
    
    if(size(circles)(2) > 8)
      continue;
    endif
        
    #cumulate results in one array [x1, y1, x2, y2 ... ]
    if(size(circles)(2) == 8)
      ok = 1;
      
      for hole=1:8
        circlesArray(hole, 1) = circles{hole}(1);  #x
        circlesArray(hole, 2) = circles{hole}(2);  #y
      endfor
              
      circlesArray = sortArray(circlesArray);
      
      for hole=1:8
        circlesArrayFlat(1, (hole-1)*2 + 1) = circlesArray(hole, 1);  #x
        circlesArrayFlat(1, (hole-1)*2 + 2) = circlesArray(hole, 2);  #y
      endfor
      
      circlesArrayFlat(1, 17) = radMin;
      circlesArrayFlat(1, 18) = radMax;
      circlesArrayFlat(1, 19) = p;
      circlesArrayFlat(1, 20) = toc;
      
      return
    endif
  endfor
  
  circlesArrayFlat = -1;
  
endfunction